Steps

1. Navigate to 'voting-app/samples/preview/apps/voteapp/metrics
2. Run './ecs-voteapp.sh'. This will trigger an update to cloudformation stack - '{environment_name}-ecs-voteapp'
3. Once the stack is updated, run './update-targetgroups.sh'
4. Prometheus runs on port: 9090, Access promotheus using this url:  http://<load-balancer-dns-name>:9090/targets
5. Grafana runs on port: 3000 to access grafana.use this url - http://<load-balancer-dns-name>:3000/?orgId=1
6. Grafana first time setup:
    1. Login using admin/admin or you can alternatively click on skip
    2. Create DataSource as follows:
        1. Name - Enter a name that represents the prometheus data source. Example - 'lattice-prometheus'
        2. Type - Select “Prometheus” from the dropdown.
        3. URL - This is the service discovery endpoint against prometheus port. Example - 'http://web.default.svc.cluster.local:9090'. Note - Service discovery endpoint can be found under cluster and prometheus configured port is 9090
        4. Access - This should be selected as 'Server(Default)'
        5. Skip other prompts, scroll down and click on 'Save & Test'. This will add the datasource and grafana should confirm that prometheus data source is accessible
    3. Add dashboard as follows:
        1. On the left hand panel, click on '+' symbol and select the option - 'Import'
        2. Select the option 'Upload .json File'. Select the file - 'envoy_grafana.json' from the path 'voting-app/samples/preview/apps/voteapp/metrics/'
        3. Select the prometheus-db source from the dropdown. This as per above example should be 'lattice-prometheus'
        4. Select 'Import' and the envoy-grafana dashboard will be imported

Grafana Screenshots:
https://raw.githubusercontent.com/aws-samples/voting-app/master/images/grafana-dashboard/grafana-setup.jpeg

There are four collapsible panels:
1. Server Statistics (global)
https://raw.githubusercontent.com/aws-samples/voting-app/master/images/grafana-dashboard/server-statistics.jpeg
2. Request/Response Summary (can be viewed by Service)
https://raw.githubusercontent.com/aws-samples/voting-app/master/images/grafana-dashboard/requests-response-summary.jpeg
3. Network Traffic Patterns (Upstream: by service, DownStream: Global)
https://raw.githubusercontent.com/aws-samples/voting-app/master/images/grafana-dashboard/network-traffic-patterns-1.jpeg
https://raw.githubusercontent.com/aws-samples/voting-app/master/images/grafana-dashboard/network-traffic-patterns-2.jpeg 
4. Network Traffic Details in Bytes ((Upstream: by service, DownStream: Global) 
https://raw.githubusercontent.com/aws-samples/voting-app/master/images/grafana-dashboard/network-traffic-details.jpeg 
