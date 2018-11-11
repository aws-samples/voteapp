#!/bin/bash
set -e
source meshvars.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

MESH_ARN=""

#TODO: Replace 'mesh' with actual CLI commands

echo ":: Creating Service Mesh ::"
{
    CMD='mesh create-mesh --cli-input-json file://config/create-mesh-voteapp.json'
    echo "Running:: $CMD"
    OUTPUT=`$CMD`
    MESH_ARN=$(echo $OUTPUT | jq -r '.mesh.metadata.arn')
    echo "MESH_ARN:: $MESH_ARN"
} || {
    echo "Err: Unable to create service mesh: $?"
    exit 1

}



echo ""
echo ":: Creating Virtual Nodes ::"

for service in $(ls $DIR/config/virtualnodes); do
    {
        CMD="mesh create-virtual-node --cli-input-json file://config/virtualnodes/$service"
        echo "Running:: $CMD"
        OUTPUT=`$CMD`
        echo $OUTPUT
    } || {
        echo "Err: Unable to create virtual node: $?"
        exit 1
    }
done

echo ""
echo ":: Creating Virtual Routers ::"

for service in $(ls $DIR/config/virtualrouters); do
    {
        CMD="mesh create-virtual-router --cli-input-json file://config/virtualrouters/$service"
        echo "Running:: $CMD"
        OUTPUT=`$CMD`
        echo $OUTPUT
    } || {
        echo "Err: Unable to create virtual router: $?"
        exit 1
    }
done


echo ""
echo ":: Creating Virtual Routes ::"

for service in $(ls $DIR/config/virtualrouters); do
    {
        CMD="mesh create-route --cli-input-json file://config/virtualroutes/$service"
        echo "Running:: $CMD"
        OUTPUT=`$CMD`
        echo $OUTPUT
    } || {
        echo "Err: Unable to create virtual router: $?"
        exit 1
    }
done
