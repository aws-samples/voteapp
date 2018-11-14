package cloudwatch

import (
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/service/cloudwatch"

	"github.com/aws-samples/voting-app/cloudwatch_agent/internal/envoy"
)

const cloudwatchMetricNamespace = "Lattice"

type Client struct {
	Session           client.ConfigProvider
	DownstreamService string
	TaskID            string
}

func (c *Client) Submit(counters envoy.CountersByUpstream, histograms envoy.HistogramsByUpstream) error {
	cwClient := cloudwatch.New(c.Session)

	for upstreamCluster, ctrs := range counters {
		dimensions := []*cloudwatch.Dimension{
			new(cloudwatch.Dimension).
				SetName("DownstreamService").
				SetValue(c.DownstreamService),
			new(cloudwatch.Dimension).
				SetName("UpstreamService").
				SetValue(upstreamCluster),
			new(cloudwatch.Dimension).
				SetName("TaskId").
				SetValue(c.TaskID),
		}
		data := []*cloudwatch.MetricDatum{
			new(cloudwatch.MetricDatum).
				SetMetricName("UpstreamRequests").
				SetDimensions(dimensions).
				SetValue(ctrs.UpstreamReq).
				SetStorageResolution(1),
			new(cloudwatch.MetricDatum).
				SetMetricName("Upstream2xxResponses").
				SetDimensions(dimensions).
				SetValue(ctrs.UpstreamResp2xx).
				SetStorageResolution(1),
			new(cloudwatch.MetricDatum).
				SetMetricName("Upstream4xxResponses").
				SetDimensions(dimensions).
				SetValue(ctrs.UpstreamResp4xx).
				SetStorageResolution(1),
			new(cloudwatch.MetricDatum).
				SetMetricName("Upstream5xxResponses").
				SetDimensions(dimensions).
				SetValue(ctrs.UpstreamResp5xx).
				SetStorageResolution(1),
			new(cloudwatch.MetricDatum).
				SetMetricName("Upstream4xxResponses").
				SetDimensions(dimensions).
				SetValue(ctrs.UpstreamResp4xx).
				SetStorageResolution(1),
		}

		if _, err := cwClient.PutMetricData(
			new(cloudwatch.PutMetricDataInput).
				SetNamespace(cloudwatchMetricNamespace).
				SetMetricData(data),
		); err != nil {
			return err
		}
	}

	for upstreamCluster, hsts := range histograms {
		dimensions := []*cloudwatch.Dimension{
			new(cloudwatch.Dimension).
				SetName("DownstreamService").
				SetValue(c.DownstreamService),
			new(cloudwatch.Dimension).
				SetName("UpstreamService").
				SetValue(upstreamCluster),
			new(cloudwatch.Dimension).
				SetName("TaskId").
				SetValue(c.TaskID),
		}

		var data []*cloudwatch.MetricDatum

		for quantile, val := range hsts {
			data = append(data,
				new(cloudwatch.MetricDatum).
					SetMetricName("UpstreamResponseTimeP"+quantile).
					SetDimensions(dimensions).
					SetValue(val).
					SetStorageResolution(1),
			)
		}

		if _, err := cwClient.PutMetricData(
			new(cloudwatch.PutMetricDataInput).
				SetNamespace(cloudwatchMetricNamespace).
				SetMetricData(data),
		); err != nil {
			return err
		}
	}
	return nil
}
