package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"time"

	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatch"

	"github.com/prometheus/common/expfmt"
)

const (
	prometheusMetricsEndpoint  = "/stats/prometheus"
	classicMetricsEndpoint     = "/stats"
	upstreamResponseMetricName = "envoy_cluster_upstream_rq"
	upstreamRequestMetricName  = "envoy_cluster_upstream_rq_total"

	// See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-metadata-endpoint-v2.html
	taskMetadataV2Endpoint = "http://169.254.170.2/v2/metadata"

	cloudwatchMetricNamespace = "Lattice"
)

type config struct {
	sess                  client.ConfigProvider
	collectFreq           time.Duration
	envoyAdminPort        int
	downstreamServiceName string
	taskID                string
}

type requestMetric struct {
	// counters
	upstreamReq, upstreamResp2xx, upstreamResp4xx, upstreamResp5xx float64

	// gauges
	// Envoy doesn't supply buckets and values for response time statistics yet,
	// so the best we can do for now is to put the precomputed histograms into CloudWatch
	// gauge metrics.   See https://github.com/envoyproxy/envoy/issues/1947
	upstreamRespTimeQuantiles map[string]float64
}

type envoyQuantileValues struct {
	Interval, Cumulative float64
}

type envoyComputedQuantiles struct {
	Name   string
	Values []envoyQuantileValues
}

type envoyHistograms struct {
	SupportedQuantiles []float64                `json:"supported_quantiles"`
	ComputedQuantiles  []envoyComputedQuantiles `json:"computed_quantiles"`
}

type envoyStat struct {
	Name       string
	Value      float64
	Histograms *envoyHistograms
}

type envoyMetrics struct {
	Stats []envoyStat
}

type taskMetadata struct {
	TaskARN string
}

func main() {
	var err error
	c := config{
		sess:                  session.Must(session.NewSession()),
		collectFreq:           5 * time.Second,
		envoyAdminPort:        8001,
		downstreamServiceName: os.Getenv("DOWNSTREAM_SERVICE_NAME"),
	}
	if c.taskID, err = getTaskID(); err != nil {
		panic(err)
	}

	c.collect()
}

// getTaskID gets the ECS task ID for the current container
func getTaskID() (string, error) {
	if url := os.Getenv("ECS_CONTAINER_METADATA_URI"); url != "" {
		return getTaskIDv3(url)
	}
	if v := os.Getenv("ECS_TASK_ID"); v != "" {
		return v, nil
	}
	return getTaskIDv2()
}

func getTaskIDv3(url string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(resp.Body); err != nil {
		return "", err
	}
	m := taskMetadata{}
	if err := json.Unmarshal(buf.Bytes(), &m); err != nil {
		return "", err
	}

	return m.TaskARN, nil
}

func getTaskIDv2() (string, error) {
	resp, err := http.Get(taskMetadataV2Endpoint)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(resp.Body); err != nil {
		return "", err
	}
	m := taskMetadata{}
	if err := json.Unmarshal(buf.Bytes(), &m); err != nil {
		return "", err
	}

	return m.TaskARN, nil
}

func (c *config) collect() {
	// First tick is immediate
	tick := time.After(0)

	for {
		<-tick
		// Subsequent ticks are on collect frequency
		tick = time.After(c.collectFreq)

		// Collect upstream request metrics from Prometheus-format endpoint
		u := url.URL{
			Scheme: "http",
			Host:   fmt.Sprintf("127.0.0.1:%d", c.envoyAdminPort),
			Path:   prometheusMetricsEndpoint,
		}

		resp, err := http.Get(u.String())
		if err != nil {
			panic(err)
		}
		defer resp.Body.Close()

		parser := new(expfmt.TextParser)
		metrics, err := parser.TextToMetricFamilies(resp.Body)
		if err != nil {
			panic(err)
		}

		upstreamRespMetrics := metrics[upstreamResponseMetricName]
		if upstreamRespMetrics == nil {
			continue
		}

		var clusterName string
		metricsByCluster := make(map[string]*requestMetric)

		for _, metric := range upstreamRespMetrics.Metric {
			count := metric.GetCounter()
			// Get cluster name first
			for _, label := range metric.GetLabel() {
				if label.GetName() == "envoy_cluster_name" {
					clusterName = label.GetValue()
				}
			}
			m, ok := metricsByCluster[clusterName]
			if !ok {
				m = new(requestMetric)
				m.upstreamRespTimeQuantiles = make(map[string]float64)
				metricsByCluster[clusterName] = m
			}

			// Collect response codes by metric now
			for _, label := range metric.GetLabel() {
				if label.GetName() == "envoy_response_code" {
					switch label.GetValue()[0] {
					case '2':
						m.upstreamResp2xx += count.GetValue()
					case '4':
						m.upstreamResp4xx += count.GetValue()
					case '5':
						m.upstreamResp5xx += count.GetValue()
					}
				}
			}
		}

		// Set total request count metric
		upstreamReqMetrics := metrics[upstreamRequestMetricName]
		if upstreamReqMetrics == nil {
			continue
		}

		for _, metric := range upstreamReqMetrics.Metric {
			for _, label := range metric.GetLabel() {
				if label.GetName() == "envoy_cluster_name" {
					clusterName = label.GetValue()
					metricsByCluster[clusterName].upstreamReq = metric.GetCounter().GetValue()
				}
			}
		}

		// Now, collect histograms from legacy endpoint (JSON)
		u = url.URL{
			Scheme: "http",
			Host:   fmt.Sprintf("127.0.0.1:%d", c.envoyAdminPort),
			Path:   classicMetricsEndpoint,
		}
		q := u.Query()
		q.Set("format", "json")
		u.RawQuery = q.Encode()

		resp, err = http.Get(u.String())
		if err != nil {
			panic(err)
		}
		defer resp.Body.Close()

		buf := new(bytes.Buffer)
		if _, err := buf.ReadFrom(resp.Body); err != nil {
			panic(err)
		}
		m := envoyMetrics{}
		if err := json.Unmarshal(buf.Bytes(), &m); err != nil {
			panic(err)
		}
		for _, stat := range m.Stats {
			if stat.Histograms != nil {
				for clusterName := range metricsByCluster {
					for _, quantiles := range stat.Histograms.ComputedQuantiles {
						if quantiles.Name == "cluster."+clusterName+".upstream_rq_time" {
							for i, valPair := range quantiles.Values {
								metricsByCluster[clusterName].upstreamRespTimeQuantiles[fmt.Sprintf("%g", stat.Histograms.SupportedQuantiles[i])] = valPair.Interval
							}
						}
					}
				}
			}
		}

		// Post to CloudWatch
		client := cloudwatch.New(c.sess)

		for clusterName, metrics := range metricsByCluster {
			dimensions := []*cloudwatch.Dimension{
				new(cloudwatch.Dimension).SetName("DownstreamService").SetValue(c.downstreamServiceName),
				new(cloudwatch.Dimension).SetName("UpstreamService").SetValue(clusterName),
				new(cloudwatch.Dimension).SetName("TaskId").SetValue(c.taskID),
			}
			data := []*cloudwatch.MetricDatum{
				new(cloudwatch.MetricDatum).SetMetricName("UpstreamRequests").SetDimensions(dimensions).SetValue(metrics.upstreamReq).SetStorageResolution(1),
				new(cloudwatch.MetricDatum).SetMetricName("Upstream2xxResponses").SetDimensions(dimensions).SetValue(metrics.upstreamResp2xx).SetStorageResolution(1),
				new(cloudwatch.MetricDatum).SetMetricName("Upstream4xxResponses").SetDimensions(dimensions).SetValue(metrics.upstreamResp4xx).SetStorageResolution(1),
				new(cloudwatch.MetricDatum).SetMetricName("Upstream5xxResponses").SetDimensions(dimensions).SetValue(metrics.upstreamResp5xx).SetStorageResolution(1),
				new(cloudwatch.MetricDatum).SetMetricName("Upstream4xxResponses").SetDimensions(dimensions).SetValue(metrics.upstreamResp4xx).SetStorageResolution(1),
			}
			for quantileName, quantileVal := range metrics.upstreamRespTimeQuantiles {
				data = append(data,
					new(cloudwatch.MetricDatum).SetMetricName("UpstreamResponseTimeP"+quantileName).SetDimensions(dimensions).SetValue(quantileVal).SetStorageResolution(1),
				)
			}
			if _, err := client.PutMetricData(
				new(cloudwatch.PutMetricDataInput).SetNamespace(cloudwatchMetricNamespace).SetMetricData(data),
			); err != nil {
				panic(err)
			}
		}
	}
}
