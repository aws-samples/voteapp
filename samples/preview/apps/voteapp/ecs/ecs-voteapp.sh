#!/bin/bash

set -ex 

ACTION=${1:-"create-stack"}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

err() {
    msg="Error: $1"
    print ${msg}
    code=${2:-"1"}
    exit ${code}
}

describe_virtual_node() {
    service=$1
    cmd=( aws --profile ${AWS_PROFILE} --region ${AWS_REGION} --endpoint-url ${LATTICE_FRONTEND} \
                lattice describe-virtual-node  \
                --mesh-name ${MESH_NAME} --virtual-node-name ${service} \
                --query virtualNode.metadata.uid --output text )
    node_id=$("${cmd[@]}") || err "Unable to describe node ${service}" "$?"
    echo ${node_id}
}

VOTE_WEB_NODE_ID=$(describe_virtual_node "web-vn")
VOTE_REPORTS_NODE_ID=$(describe_virtual_node "reports-vn")

aws --profile ${AWS_PROFILE} --region ${AWS_REGION} \
    cloudformation ${ACTION} \
    --stack-name ${ENVIRONMENT_NAME}-ecs-voteapp \
    --capabilities CAPABILITY_IAM \
    --template-body file://${DIR}/ecs-voteapp.yaml  \
    --parameters \
    ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME} \
    ParameterKey=VoteWebNodeId,ParameterValue="${VOTE_WEB_NODE_ID}" \
    ParameterKey=VoteReportsNodeId,ParameterValue="${VOTE_REPORTS_NODE_ID}"
