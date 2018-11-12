#!/bin/sh

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
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-mesh --cli-input-json file:///$DIR/config/mesh/mesh.json )
    print "${cmd[@]}"
    out=$("${cmd[@]}") || err "Unable to create service mesh" "$?"
    arn=$(echo $out | jq -r '.mesh.metadata.arn')
    print "--> $arn"
}

create_virtual_node() {
    service=$1
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-virtual-node --cli-input-json file:///$DIR/config/virtualnodes/$service )
    print "${cmd[@]}"
    out=$("${cmd[@]}") || err "Unable to create virtual node" "$?"
    arn=$(echo $out | jq -r '.virtualNode.metadata.arn')
    print "--> $arn"
}

create_virtual_nodes() {
    print "Creating virtual nodes"
    print "======================"
    for service in $(ls $DIR/config/virtualnodes); do
        create_virtual_node $service
    done
}

create_virtual_router() {
    service=$1
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-virtual-router --cli-input-json file:///$DIR/config/virtualrouters/$service )
    print "${cmd[@]}"
    out=$("${cmd[@]}") || err "Unable to create virtual router" "$?"
    arn=$(echo $out | jq -r '.virtualRouter.metadata.arn')
    print "--> $arn"
}

create_virtual_routers() {
    print "Creating virtual routers"
    print "========================"
    for service in $(ls $DIR/config/virtualrouters); do
        create_virtual_router $service
    done
}

create_virtual_route() {
    service=$1
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-route --cli-input-json file:///$DIR/config/virtualroutes/$service )
    print "${cmd[@]}"
    out=$("${cmd[@]}") || err "Unable to create virtual route" "$?"
    arn=$(echo $out | jq -r '.route.metadata.arn')
    print "--> $arn"
}

create_virtual_routes() {
    print "Creating virtual routes"
    print "======================="
    for service in $(ls $DIR/config/virtualrouters); do
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
