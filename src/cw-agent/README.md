Envoy-CloudWatch Agent
======================
This directory contains code for a simple agent that retrieves metrics from the
Envoy traffic proxy and forwards them to CloudWatch.

Prerequisites
-------------
The following environment variables must be declared:

| Variable                  | Description                                                                                          |
| ------------------------- | ---------------------------------------------------------------------------------------------------- |
| `DOWNSTREAM_SERVICE_NAME` | The downstream (local) service name.  Used for setting the `DownstreamServiceName` metric dimension. |
| `ENVOY_ADMIN_HOST`        | The IP and port of Envoy's admin service, for example, `localhost:9901`                              |

Optional configuration
----------------------
The following environment variables can be used for debugging or tuning:

| Variable            | Description                                                                                                                                                          |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `COLLECT_FREQUENCY` | Adjust the collection frequency (default: `5s`).  Don't increase the frequency to a value higher than Envoy's configured stats flush frequency (normally 5 seconds). |


Published metrics
-----------------
Published metrics include:

| Metric                   | Description                                                                                           |
| ------------------------ | ----------------------------------------------------------------------------------------------------- |
| UpstreamRequests         | Count of requests sent to the upstream service                                                        |
| Upstream2xxResponses     | Count of 2xx responses from the upstream service                                                      |
| Upstream4xxResponses     | Count of 2xx responses from the upstream service                                                      |
| Upstream5xxResponses     | Count of 2xx responses from the upstream service                                                      |
| UpstreamResponseTimePxxx | Upstream response latency, in ms, by quantile.  Supported quantiles are P0,P25,P50,P75,P99,P99.9,P100 |

The metrics have the following dimensions:

| Dimension         | Description                     |
| ----------------- | ------------------------------- |
| DownstreamService | Downstream (local) service name |
| UpstreamService   | Upstream (remote) service name  |


Screenshots
-----------
![CloudWatch screenshot](../../images/cloudwatch-sample.png?raw=true)

Build instructions
------------------

A `Dockerfile` is included.  Run:

```
docker build -t <tag>
```
