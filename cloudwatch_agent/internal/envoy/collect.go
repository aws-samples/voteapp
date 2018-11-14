package envoy

func (coll *Collector) Collect() (CountersByUpstream, HistogramsByUpstream, error) {
	var (
		err        error
		counters   CountersByUpstream
		histograms HistogramsByUpstream
	)

	counters, err = coll.collectCounters()
	if err != nil {
		return counters, histograms, err
	}

	var upstreamClusters []string
	for cluster := range counters {
		upstreamClusters = append(upstreamClusters, cluster)
	}

	histograms, err = coll.collectHistograms(upstreamClusters)
	if err != nil {
		return counters, histograms, err
	}

	return counters, histograms, nil
}
