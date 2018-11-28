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

VOTE_WEB_NODE_ID="mesh/${MESH_NAME}/virtualNode/web-vn"
VOTE_VOTES_NODE_ID="mesh/${MESH_NAME}/virtualNode/votes-vn"
VOTE_REPORTS_NODE_ID="mesh/${MESH_NAME}/virtualNode/reports-vn"
VOTE_REPORTS_V2_NODE_ID="mesh/${MESH_NAME}/virtualNode/reports-vn-v2"
VOTE_DATABASE_NODE_ID="mesh/${MESH_NAME}/virtualNode/database-vn"

aws --profile ${AWS_PROFILE} --region ${AWS_REGION} \
    cloudformation ${ACTION} \
    --stack-name ${ENVIRONMENT_NAME}-ecs-voteapp \
    --capabilities CAPABILITY_IAM \
    --template-body file://${DIR}/ecs-voteapp.yaml  \
    --parameters \
    ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME} \
    ParameterKey=VoteWebNodeId,ParameterValue="${VOTE_WEB_NODE_ID}" \
    ParameterKey=VoteVotesNodeId,ParameterValue="${VOTE_VOTES_NODE_ID}" \
    ParameterKey=VoteReportsNodeId,ParameterValue="${VOTE_REPORTS_NODE_ID}" \
    ParameterKey=VoteReportsV2NodeId,ParameterValue="${VOTE_REPORTS_V2_NODE_ID}" \
    ParameterKey=VoteDatabaseNodeId,ParameterValue="${VOTE_DATABASE_NODE_ID}"
