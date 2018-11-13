#!/usr/bin/env bash
# vim:syn=sh:ts=4:sw=4:et:ai

shopt -s nullglob

# Optional pre-load script
if [ -f meshvars.sh ]; then
    source meshvars.sh
fi

# Only us-west-2 is supported right now.
: ${AWS_DEFAULT_REGION:=us-west-2}
export AWS_DEFAULT_REGION

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

sanity_check() {
    if [ "$AWS_DEFAULT_REGION" != "us-west-2" ]; then
        err "Only us-west-2 is supported at this time.  (Current default region: $AWS_DEFAULT_REGION)"
    fi
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
    sanity_check
    create_mesh
    create_virtual_nodes
    create_virtual_routers
    create_virtual_routes
}

main
