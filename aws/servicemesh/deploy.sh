#!/usr/bin/env bash

shopt -s nullglob

# Ensure your AWS profile (specified in meshvars.sh) sets the default region
if [ -f meshvars.sh ]; then
    source meshvars.sh
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

print() {
    printf "[MESH] %s\n" "$*"
}

err() {
    msg="Error: $1"
    print $msg
    code=${2:-"1"}
    exit $code
}

create_mesh() {
    print "Creating service mesh"
    print "====================="
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-mesh --cli-input-json file:///$DIR/config/mesh/mesh.json --query mesh.metadata.arn --output text )
    print "${cmd[@]}"
    arn=$("${cmd[@]}") || err "Unable to create service mesh" "$?"
    print "--> $arn"
}

create_virtual_node() {
    service=$1
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-virtual-node --cli-input-json file:///$DIR/config/virtualnodes/$service --query virtualNode.metadata.arn --output text )
    print "${cmd[@]}"
    arn=$("${cmd[@]}") || err "Unable to create virtual node" "$?"
    print "--> $arn"
}

create_virtual_nodes() {
    print "Creating virtual nodes"
    print "======================"
    for service in $DIR/config/virtualnodes/*.json; do
        create_virtual_node $service
    done
}

create_virtual_router() {
    service=$1
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-virtual-router --cli-input-json file:///$DIR/config/virtualrouters/$service --query virtualRouter.metadata.arn --output text )
    print "${cmd[@]}"
    arn=$("${cmd[@]}") || err "Unable to create virtual router" "$?"
    print "--> $arn"
}

create_virtual_routers() {
    print "Creating virtual routers"
    print "========================"
    for service in $DIR/config/virtualrouters/*.json; do
        create_virtual_router $service
    done
}

create_virtual_route() {
    service=$1
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-route --cli-input-json file:///$DIR/config/virtualroutes/$service --query route.metadata.arn --output text )
    print "${cmd[@]}"
    arn=$("${cmd[@]}") || err "Unable to create virtual route" "$?"
    print "--> $arn"
}

create_virtual_routes() {
    print "Creating virtual routes"
    print "======================="
    for service in $DIR/config/virtualrouters/*.json; do
        create_virtual_route $service
    done
}

main() {
    create_mesh
    create_virtual_nodes
    create_virtual_routers
    create_virtual_routes
}

main
