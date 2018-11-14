package envoy

type Collector struct {
	AdminHost string
}

// Value by quantile (P75, P90, etc.)
type Histogram map[string]float64

type Counters struct {
	// Counters
	UpstreamReq,
	UpstreamResp2xx,
	UpstreamResp4xx,
	UpstreamResp5xx float64
}

type UpstreamCluster string

type CountersByUpstream map[string]*Counters
type HistogramsByUpstream map[string]Histogram
