# Envoy Docker Image for Lattice

This is a Docker file based off of Envoy that has an entrypoint that writes out a config for boostraping the Envoy with Lattice Service Mesh. It has some environment variables that are used in the creation of the bootstrap file.

- ```LATTICE_VIRTUAL_NODE_UID``` - _**Required**_ for Envoy to idetifiy itself to the Lattice control plane. If you do not set this value the startup script will exit. **Example**: ```4af36ad7-18c7-41d0-838a-32a0168deb90```

- ```EC2_REGION``` - _**Required**_ to tell envoy which regional endpoint to talk to when registering. If this is __not__ set it will attempt to read the EC2 metadata service and extract the region from the AZ metadata. Example: ```us-west-2```

- ```ENVOY_TRACING_CFG``` - Valid YAML that will allow for addition of tracing configuration. Should have **'tracing'** as the root.

Example:
```yaml
tracing:
  http:
    name: MyName
```
Or as a single line
```yaml
tracing: { http: {name: Myname, config: { account: 1234 } }
```


- ```ENVOY_STATS_SINKS_CFG``` - Valid YAML that conforms to this Envoy specfication: [StatsSink](https://www.envoyproxy.io/docs/envoy/v1.8.0/api-v2/config/metrics/v2/stats.proto#envoy-api-msg-config-metrics-v2-statssink). Should have **'stats_sinks'** as its root.
```yaml
Need to put an example here.
```
- ```ENVOY_STATS_CONFIG``` - Valid YAML that conforms to this envoy specification: [StatsConfig](https://www.envoyproxy.io/docs/envoy/v1.8.0/api-v2/config/metrics/v2/stats.proto#envoy-api-msg-config-metrics-v2-statsconfig). Should have **'stats_config'** as the root.
```yaml
Need to put example here.
```

- ```ENVOY_STATS_FLUSH_INTERVAL``` - A number that represents the miliseconds between flushes to configured stats sinks. **Example**: ```500```