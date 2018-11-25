#!/bin/bash -e

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"


mesh_name=${MESH_NAME:-simpleapp}
echo "Using EnvironmentName=$mesh_name"

profile=${AWS_PROFILE:-default}
echo "Profile: $profile"

region=${AWS_REGION:-us-west-2}
echo "Region: $region"

config_dir=${CONFIG_DIR:-$dir/../config}
echo "Using config in '$config_dir'"

endpoint_url=${APPMESH_ENDPOINT_URL:-https://frontend.us-west-2.gamma.lattice.aws.a2z.com/}
aws="aws --profile ${profile} --region ${region}"

echo "Validating $mesh_name-vpc stack"
${aws} cloudformation validate-template \
  --template-body file://${config_dir}/cftemplates/vpc-stack.yaml >> /dev/null

echo "Creating $mesh_name-vpc stack"
echo "$(${aws} cloudformation create-stack \
  --template-body file://${config_dir}/cftemplates/vpc-stack.yaml \
  --stack-name="$mesh_name-vpc")"

echo "Waiting for $mesh_name-vpc stack to complete."
${aws} cloudformation wait stack-create-complete --stack-name="$mesh_name-vpc"

echo "Validating $mesh_name-ecs stack"
${aws} cloudformation validate-template \
  --template-body file://${config_dir}/cftemplates/ecs-stack.yaml >> /dev/null

echo "Creating $mesh_name-ecs stack"
echo "$(${aws} cloudformation create-stack \
  --template-body file://${config_dir}/cftemplates/ecs-stack.yaml \
  --stack-name "$mesh_name-ecs" \
  --capabilities CAPABILITY_IAM \
  --parameters \
      ParameterKey=EnvironmentName,ParameterValue=${mesh_name} \
      ParameterKey=KeyName,ParameterValue=${KEY_PAIR_NAME})"

echo "Waiting for $mesh_name-ecs stack to complete."
${aws} cloudformation wait stack-create-complete --stack-name "$mesh_name-ecs"

cmd="${aws} --endpoint-url ${endpoint_url} appmesh"

${cmd} create-mesh --client-token ${mesh_name} --mesh-name ${mesh_name}

# ServiceA
echo "Creating Virtual node for ServiceAv1"
${cmd} create-virtual-node --cli-input-json file://${config_dir}/latticecfg/serviceAv1-virtual-node.json --mesh-name ${mesh_name}

echo "Creating Virtual router for ServiceA"
${cmd} create-virtual-router --cli-input-json file://${config_dir}/latticecfg/serviceA-router.json --mesh-name ${mesh_name}

echo "Creating routes for ServiceA"
${cmd} create-route --cli-input-json file://${config_dir}/latticecfg/serviceA-routes.json --mesh-name ${mesh_name}

# ServiceB
echo "Creating Virtual node for ServiceBv1"
${cmd} create-virtual-node --cli-input-json file://${config_dir}/latticecfg/serviceBv1-virtual-node.json --mesh-name ${mesh_name} 

echo "Creating Virtual router for ServiceB"
${cmd} create-virtual-router --cli-input-json file://${config_dir}/latticecfg/serviceB-router.json --mesh-name ${mesh_name}

echo "Creating routes for ServiceB"
${cmd} create-route --cli-input-json file://${config_dir}/latticecfg/serviceB-routes.json --mesh-name ${mesh_name}

# ServiceC
echo "Creating Virtual node for ServiceCv1"
${cmd} create-virtual-node --cli-input-json file://${config_dir}/latticecfg/serviceCv1-virtual-node.json --mesh-name ${mesh_name}

echo "Creating Virtual router for ServiceC"
${cmd} create-virtual-router --cli-input-json file://${config_dir}/latticecfg/serviceC-router.json --mesh-name ${mesh_name}

echo "Creating routes for ServiceC"
${cmd} create-route --cli-input-json file://${config_dir}/latticecfg/serviceC-routes.json --mesh-name ${mesh_name}

# ServiceD
echo "Creating Virtual node for ServiceDv1"
${cmd} create-virtual-node --cli-input-json file://${config_dir}/latticecfg/serviceDv1-virtual-node.json --mesh-name ${mesh_name}

echo "Creating Virtual router for ServiceD"
${cmd} create-virtual-router --cli-input-json file://${config_dir}/latticecfg/serviceD-router.json --mesh-name ${mesh_name}

echo "Creating routes for ServiceD"
${cmd} create-route --cli-input-json file://${config_dir}/latticecfg/serviceD-routes.json --mesh-name ${mesh_name}

#
echo "Getting Virtual Node Ids"
srvAv1_vnode=$(${cmd} describe-virtual-node --mesh-name ${mesh_name} --virtual-node-name serviceAv1)
srvBv1_vnode=$(${cmd} describe-virtual-node --mesh-name ${mesh_name} --virtual-node-name serviceBv1)
srvCv1_vnode=$(${cmd} describe-virtual-node --mesh-name ${mesh_name} --virtual-node-name serviceCv1)
srvDv1_vnode=$(${cmd} describe-virtual-node --mesh-name ${mesh_name} --virtual-node-name serviceDv1)
srvAv1_uid=$(echo "$srvAv1_vnode" | jq '.virtualNode.metadata.uid' | sed s/\"//g)
srvBv1_uid=$(echo "$srvBv1_vnode" | jq '.virtualNode.metadata.uid' | sed s/\"//g)
srvCv1_uid=$(echo "$srvCv1_vnode" | jq '.virtualNode.metadata.uid' | sed s/\"//g)
srvDv1_uid=$(echo "$srvDv1_vnode" | jq '.virtualNode.metadata.uid' | sed s/\"//g)

echo "Got $srvAv1_uid, $srvBv1_uid , $srvCv1_uid, $srvDv1_uid"

echo "Creating $mesh_name-app stack"
echo "Validating $mesh_name-app stack"
aws cloudformation validate-template \
  --template-body file://${config_dir}/cftemplates/app-stack.yaml >> /dev/null

echo "Creating $mesh_name-app stack"
echo "$(aws cloudformation create-stack \
  --template-body file://${config_dir}/cftemplates/app-stack.yaml \
  --stack-name "$mesh_name-app" \
  --capabilities CAPABILITY_IAM \
  --parameters \
      ParameterKey=EnvironmentName,ParameterValue=${mesh_name} \
      ParameterKey=ServiceAv1ServiceEndpointIdentifier,ParameterValue=${srvAv1_uid} \
      ParameterKey=ServiceBv1ServiceEndpointIdentifier,ParameterValue=${srvBv1_uid} \
      ParameterKey=ServiceCv1ServiceEndpointIdentifier,ParameterValue=${srvCv1_uid} \
      ParameterKey=ServiceDv1ServiceEndpointIdentifier,ParameterValue=${srvDv1_uid})"

echo "Waiting for $mesh_name-app stack to complete."
aws cloudformation wait stack-create-complete --stack-name "$mesh_name-app"
