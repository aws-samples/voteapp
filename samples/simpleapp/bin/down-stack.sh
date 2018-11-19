#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

mesh_name=${MESH_NAME:-simpleapp}
echo "Using EnvironmentName=$mesh_name"

profile=${AWS_PROFILE:-default}
echo "Profile: $profile"

region=${AWS_REGION:-us-west-2}
echo "Region: $region"

config_dir=${CONFIG_DIR:-$dir/../config}
echo "Using config in '$CONFIG_DIR'"

endpoint_url=${LATTICE_ENDPOINT_URL:-https://frontend.us-west-2.gamma.lattice.aws.a2z.com/}
aws="aws --profile ${profile} --region ${region}"


echo "Deleting $mesh_name-app stack"
${aws} cloudformation delete-stack --stack-name="$mesh_name-app"
${aws} cloudformation wait stack-delete-complete --stack-name="$mesh_name-app"

echo "Deleting $mesh_name-ecs stack"
${aws} cloudformation delete-stack --stack-name="$mesh_name-ecs"
${aws} cloudformation wait stack-delete-complete --stack-name="$mesh_name-ecs"

echo "Deleting $mesh_name-vpc stack"
${aws} cloudformation delete-stack --stack-name="$mesh_name-vpc"
${aws} cloudformation wait stack-delete-complete --stack-name="$mesh_name-vpc"

lattice="${aws} --endpoint-url ${endpoint_url} lattice"
${lattice} delete-virtual-node --mesh-name "$mesh_name" --virtual-node-name "serviceAv1"
${lattice} delete-virtual-node --mesh-name "$mesh_name" --virtual-node-name "serviceBv1"