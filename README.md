# Vote App

The Vote App is a simple application to demonstrate microservices running under App Mesh.
It is based on the original Docker version (see [ATTRIBUTION]).

![Vote App architecture]

To learn more about the project repo, see this [orientation].

## Quick Start

### Prerequisites

Before deploying the Vote App, you will need a functional VPC,
ECS cluster, and service mesh.

Bash scripts and CloudFormation stack templates are provided under the
`config` directory to create the necessary resources to run the
Vote App.

The following environment variables must be exported before running the
scripts:

```sh
# The prefix to use for created stack resources
export ENVIRONMENT_NAME=mesh-demo

# The AWS CLI profile (can specify "default")
export AWS_PROFILE="tony"

# The AWS region to deploy to; valid regions during preview:
# us-west-2 | us-east-1 | us-east-2 | eu-west-1
export AWS_REGION="us-west-2"
export KEY_PAIR_NAME="my-key-pair"

# The name to use for your app mesh 
export MESH_NAME="default"

# The domain to use for service discovery
export SERVICES_DOMAIN="${MESH_NAME}.svc.cluster.local"

# Optional: the number of physical nodes (EC2 instances) to join the
# ECS cluster (the default is 5)
export CLUSTER_SIZE=5
```


#### 1. Deploy VPC

```sh
$ ./config/infrastructure/vpc.sh
```


#### 2. Deploy Mesh

This step will set up the necessary app mesh resources (virtual nodes,
virtual routers, and routes)..

To perform this step, you will first need to install the latest version of
the [AWS CLI].


```sh
$ ./config/appmesh/deploy-mesh.sh 
```


#### 3. Deploy ECS Cluster

```sh
$ ./config/infrastructure/ecs-cluster.sh
```


### Deploy the Vote App

```sh
$ ./config/ecs/ecs-voteapp.sh
...
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - mesh-demo-ecs-voteapp
[ecs-voteapp.sh] Public endpoints
[ecs-voteapp.sh] ================
[ecs-voteapp.sh] voteapp: http://mesh-Publi-142LFAOM1M1V5-2012495322.us-west-2.elb.amazonaws.com
[ecs-voteapp.sh] prometheus: http://mesh-Publi-142LFAOM1M1V5-2012495322.us-west-2.elb.amazonaws.com:9090/targets
[ecs-voteapp.sh] grafana: http://mesh-Publi-142LFAOM1M1V5-2012495322.us-west-2.elb.amazonaws.com:3000
[ecs-voteapp.sh] logs: https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logStream:group=mesh-demo-ecs-cluster-ECSServiceLogGroup-16Q5XXLI1B7UP
```

For convenience, save the output from the above command in a text file that you can source into your bash shell:

voteapp.env
```sh
# vote app
export EP=http://mesh-Publi-142LFAOM1M1V5-2012495322.us-west-2.elb.amazonaws.com
alias vote="docker run -it --rm -e WEB_URI=$EP subfuzion/vote vote"
alias results="docker run -it --rm -e WEB_URI=$EP subfuzion/vote results"
#
export PROMETHEUS_EP="$EP:9090/targets"
alias prometheus="open $PROMETHEUS_EP"
#
export GRAFANA_EP="$EP:3000/?orgId=1"
alias grafana="open $GRAFANA_EP"

```

If you saved the above to a file called `voteapp.env`, you can source it in like this:

```sh
source voteapp.env
```

#### Testing with the Voter client

You can test the app by running the `voter` CLI in your terminal. Set your shell environment
as shown in the previous section after deploying the app.

```sh
$ vote
? What do you like better? (Use arrow keys)
  (quit)
❯ cats
  dogs
```

You can print voting results:

```sh
$ results
Total votes -> cats: 4, dogs: 0 ... CATS WIN!
```

### Observability

#### CloudWatch

TODO

#### X-Ray

Use X-Ray to trace requests between services (optional).

For further information about how to use X-Ray to trace requests as they are routed 
between different services, see the [README](./observability/x-ray.md).


#### Grafana / Prometheus.

If you want to use Grafana to visualize metrics from Envoy run

```sh
$ ./config/ecs/update-targetgroups.sh 
```

This will register the IP address of the task running Grafana and Prometheus 
with their respective target groups.  When finished, you should be able to access 
Grafana from http://<load_balancer_dns_name>:3000.  To configure Grafana, follow 
the instructions in the [README](./config/metrics/README.md).


[ATTRIBUTION]:            ./ATTRIBUTION.md
[orientation]:            http://bit.ly/vote-app-orientation
[AWS CLI]:                https://docs.aws.amazon.com/cli/latest/userguide/installing.html
[deploy with Fargate]:    https://read.acloud.guru/deploy-the-voting-app-to-aws-ecs-with-fargate-cb75f226408f
[Vote App architecture]:  ./resources/voting-app-arch-3.png
[LICENSE]:                ./LICENSE

