# Overview
Voting App

## Setup

### Prerequisites
Following steps assume you have a functional VPC, ECS-Cluster and Mesh. If not follow the steps under ***infrastructure***. And have the following environment variables set

```
export AWS_PROFILE=<...>
export AWS_REGION=<...>
export ENVIRONMENT_NAME=<...>
export MESH_NAME=<...>
```

### Steps

* Setup virtual-nodes, virtual-router and routes for app service mesh

```
$ ./servicemesh/deploy.sh
```

* Deploy app to ECS

```
$ ./ecs/ecs-voteapp.sh
```

* Verify by doing a curl on the web service

```
<ec2-bastion-host>$ curl -s http://web.default.svc.cluster.local:9080/results
```
