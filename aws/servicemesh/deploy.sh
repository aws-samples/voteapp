#!/usr/bin/env bash
# vim:syn=sh:ts=4:sw=4:et:ai

shopt -s nullglob

# Optional pre-load script
if [ -f meshvars.sh ]; then
    source meshvars.sh
fi

# Only us-west-2 is supported right now.
: ${AWS_DEFAULT_REGION:=us-west-2}

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
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-virtual-node --cli-input-json file:///$DIR/config/virtualnodes/$service --query virtualNode.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}") || err "Unable to create virtual node" "$?"
    print "--> $uid"
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
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-virtual-router --cli-input-json file:///$DIR/config/virtualrouters/$service --query virtualRouter.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}") || err "Unable to create virtual router" "$?"
    print "--> $uid"
}

create_virtual_routers() {
    print "Creating virtual routers"
    print "========================"
    for service in $(ls $DIR/config/virtualrouters); do
        create_virtual_router $service
    done
}

#
# BUG: there is a CLI bug prevent this code from working right now
#
# create_virtual_route() {
#     service=$1
#     cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-route --cli-input-json file:///$DIR/config/routes/$service --query route.metadata.uid --output text )
#     print "${cmd[@]}"
#     uid=$("${cmd[@]}") || err "Unable to create virtual route" "$?"
#     print "--> $uid"
# }

# create_virtual_routes() {
#     print "Creating virtual routes"
#     print "======================="
#     for service in $(ls $DIR/config/routes); do
#         create_virtual_route $service
#     done
# }

#
# HACK version
# BUG: still doesn't do any good...
#     An error occurred (BadRequestException) when calling the CreateRoute operation: HTTP route action cannot be null/empty.
#     [MESH] Error: Unable to create virtual route: database
#
create_virtual_route() {
    route=$1
    cmd=( aws --endpoint-url $LATTICE_FRONTEND lattice create-route --cli-input-json file:///$DIR/config/routes/vr_${route}.json
        --route-name $route \
        --virtual-router-name ${route}_router \
        --query route.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}") || err "Unable to create virtual route: $route" "$?"
    print "--> $uid"
}
create_virtual_routes() {
    print "Creating virtual routes"
    print "======================="
    routes=(database queue reports votes)
    for route in ${routes[@]}; do
        create_virtual_route $route
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
