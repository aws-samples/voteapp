#!/bin/bash

set -ex 

ACTION=${1:-"create-stack"}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
MESHCMD=appmesh

err() {
    msg="Error: $1"
    print ${msg}
    code=${2:-"1"}
    exit ${code}
}

describe_virtual_node() {
    service=$1
    cmd=( aws --profile ${AWS_PROFILE} --region ${AWS_REGION} --endpoint-url ${APPMESH_FRONTEND} \
                $MESHCMD describe-virtual-node  \
                --mesh-name ${MESH_NAME} --virtual-node-name ${service} \
                --query virtualNode.metadata.uid --output text )
    node_id=$("${cmd[@]}") || err "Unable to describe node ${service}" "$?"
    echo ${node_id}
}

COLOR_GATEWAY_NODE_ID=$(describe_virtual_node "colorgateway-vn")
COLOR_TELLER_NODE_ID=$(describe_virtual_node "colorteller-vn")
COLOR_TELLER_BLACK_NODE_ID=$(describe_virtual_node "colorteller-black-vn")
COLOR_TELLER_BLUE_NODE_ID=$(describe_virtual_node "colorteller-blue-vn")
COLOR_TELLER_RED_NODE_ID=$(describe_virtual_node "colorteller-red-vn")

aws --profile ${AWS_PROFILE} --region ${AWS_REGION} \
    cloudformation ${ACTION} \
    --stack-name ${ENVIRONMENT_NAME}-ecs-colorapp \
    --capabilities CAPABILITY_IAM \
    --template-body file://${DIR}/ecs-colorapp.yaml  \
    --parameters \
    ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME} \
    ParameterKey=ColorGatewayNodeId,ParameterValue="${COLOR_GATEWAY_NODE_ID}" \
    ParameterKey=ColorTellerNodeId,ParameterValue="${COLOR_TELLER_NODE_ID}" \
    ParameterKey=ColorTellerBlackNodeId,ParameterValue="${COLOR_TELLER_BLACK_NODE_ID}" \
    ParameterKey=ColorTellerBlueNodeId,ParameterValue="${COLOR_TELLER_BLUE_NODE_ID}" \
    ParameterKey=ColorTellerRedNodeId,ParameterValue="${COLOR_TELLER_RED_NODE_ID}"
