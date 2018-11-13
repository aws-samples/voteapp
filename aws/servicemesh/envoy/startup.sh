#!/bin/bash
bootstrap_file_name="envoy-bootstrap.yaml"
if [ ! -f $bootstrap_file_name ]; then
  echo "No '$bootstrap_file_name' file found. Creating one!"
  if [ -z "$LATTICE_VIRTUAL_NODE_UID" ]; then
    (>&2 echo "LATTICE_VIRTUAL_NODE_UID environment variable not set. Cannot start")
    exit 1;
  fi

  if [ -z "$EC2_REGION" ]; then
    EC2_AVAIL_ZONE=`curl --connect-timeout 2 -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
    EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
    if [ -z "$EC2_REGION" ]; then
      (>&2 echo "Region could not be found or was not set in EC2_REGION environment variable. Cannot start.")
      exit 2;
    fi
  fi

  if [ ! -z "$ENVOY_STATS_FLUSH_INTERVAL" ]; then
    flush_interval="stats_flush_interval: $ENVOY_STATS_FLUSH_INTERVAL"
  fi
  

  cat <<BOOTSTRAP  >> $bootstrap_file_name
admin:
  access_log_path: /tmp/admin_access.log
  # So you can do <envoy hostname>:9901/config_dump
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }

node:
   #  Currently, the identifier you want to use here is the metadata.uid from
   #  describe-virtual-node. For example...
   #
   #  {
   #   "virtualNode": {
   #       "status": {
   #           "status": "ACTIVE"
   #       },
   #       "meshName": "sample",
   #       "virtualNodeName": "a-sample-v-node",
   #       "spec": {
   #           "serviceDiscovery": {
   #               "dns": {
   #                   "serviceName": "a-sample-v-node.local"
   #               }
   #           },
   #           "listeners": [
   #               {
   #                   "portMapping": {
   #                       "protocol": "http",
   #                       "port": 9080
   #                   }
   #               }
   #           ],
   #           "backends": []
   #       },
   #       "metadata": {
   #           "version": 1,
   #           "lastUpdatedAt": 1540767451.02,
   #           "createdAt": 1540767451.02,
   #           "arn": "arn:aws:lattice:us-west-2:123456789012:mesh/sample/virtualNode/a-sample-v-node",
   #           "uid": "0000000-00000-0000-0000-000000000000" <--- THIS FIELD
   #       }
   #   }
   #  }
   id: $LATTICE_VIRTUAL_NODE_UID
dynamic_resources:
  # Configure ADS, then declare that clusters and routes should also come from
  # Lattice. Lattice will inline
  ads_config:
    api_type: GRPC
    grpc_services:
      envoy_grpc:
        cluster_name: lattice_ads
  lds_config: {ads: {}}
  cds_config: {ads: {}}
static_resources:
  clusters:
  # Defines Lattice upstream ADS cluster for configuration.
  - name: lattice_ads
    connect_timeout: 5s
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    http2_protocol_options: {}
    # At the moment, Lattice ADS endpoints do not support alpn, so this
    # effectively disables it
    tls_context:
       common_tls_context:
          alpn_protocols: [“http/1.1”]
    hosts: [{ socket_address: { address: "envoy-management.$EC2_REGION.gamma.lattice.aws.a2z.com", port_value: 443}}]
$ENVOY_TRACING_CFG
$ENVOY_STATS_SINKS_CFG
$ENVOY_STATS_CONFIG
$flush_interval
BOOTSTRAP
fi

exec "$@"