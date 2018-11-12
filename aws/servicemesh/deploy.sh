#!/bin/sh

# TODO: remove this when mesh an be replaced with full cli command
if [ -f meshvars.sh ]; then
    source meshvars.sh
fi

# Ensure your AWS profile (specified in meshvars.sh) sets the default region
MESHCMD="aws --endpoint-url $LATTICE_FRONTEND lattice'"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

print() {
    printf "[MESH] %s\n" "$*"
}

err() {
    msg="Error: $*"
    print $msg
    code=${2:-"1"}
    exit $code
}

create_mesh() {
    print "Creating service mesh"
    {
        CMD="$MESHCMD create-mesh --cli-input-json file://config/create-mesh-voteapp.json"
        print "run: $CMD"
        OUTPUT=$($CMD)
        MESH_ARN=$(echo $OUTPUT | jq -r '.mesh.metadata.arn')
        print "MESH_ARN: $MESH_ARN"
    } || {
        err "Unable to create service mesh" "$?"
    }
}

create_virtual_node() {
    service=$1
    {
        CMD="$MESHCMD create-virtual-node --cli-input-json file://config/virtualnodes/$service"
        print "run: $CMD"
        OUTPUT=$($CMD)
        print $OUTPUT
    } || {
        err "Unable to create virtual node" "$?"
    }
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
    {
        CMD="$MESHCMD create-virtual-router --cli-input-json file://config/virtualrouters/$service"
        print "run: $CMD"
        OUTPUT=$($CMD)
        print $OUTPUT
    } || {
        err "Unable to create virtual router" "$?"
    }
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
    {
        CMD="$MESHCMD create-route --cli-input-json file://config/virtualroutes/$service"
        print "run: $CMD"
        OUTPUT=$($CMD)
        print $OUTPUT
    } || {
        err "Unable to create virtual route" "$?"
    }
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
}

main
