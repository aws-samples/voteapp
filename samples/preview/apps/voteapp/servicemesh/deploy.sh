#!/usr/bin/env bash
# vim:syn=sh:ts=4:sw=4:et:ai

shopt -s nullglob

# Optional pre-load script
if [ -f meshvars.sh ]; then
    source meshvars.sh
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
MESHCMD=appmesh

print() {
    printf "[MESH] %s\n" "$*"
}

err() {
    msg="Error: $1"
    print ${msg}
    code=${2:-"1"}
    exit ${code}
}

sanity_check() {
    if [ "${AWS_REGION}" != "us-west-2" ]; then
        err "Only us-west-2 is supported at this time.  (Current default region: ${AWS_REGION})"
    fi

    if [ -z ${MESH_NAME} ]; then
        err "MESH_NAME is not set"
    fi
}

create_mesh() {
    print "Creating/updating service mesh"
    print "=============================="
    cmd=( aws --region ${AWS_REGION} $MESHCMD create-mesh --mesh-name ${MESH_NAME} --query mesh.metadata.arn --output text )
    print "${cmd[@]}"
    arn=$("${cmd[@]}") || err "Unable to create service mesh" "$?"
    print "--> $arn"
}

create_virtual_node() {
    service=$1
    cmd=( aws --region ${AWS_REGION} $MESHCMD create-virtual-node --mesh-name ${MESH_NAME} --cli-input-json file:///${DIR}/config/virtualnodes/${service} --query virtualNode.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}") || err "Unable to create/update virtual node" "$?"
    print "--> ${uid}"
}

update_virtual_node() {
    service=$1
    cmd=( aws --region ${AWS_REGION} $MESHCMD update-virtual-node --mesh-name ${MESH_NAME} --cli-input-json file:///${DIR}/config/virtualnodes/${service} --query virtualNode.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}" 2>/dev/null) || create_virtual_node ${service}
    print "--> ${uid}"
}

configure_virtual_nodes() {
    print "Creating/updating virtual nodes"
    print "==============================="
    for service in $(ls ${DIR}/config/virtualnodes); do
        update_virtual_node ${service}
    done
}

create_virtual_router() {
    service=$1
    cmd=( aws --region ${AWS_REGION} $MESHCMD create-virtual-router --mesh-name ${MESH_NAME} --cli-input-json file:///${DIR}/config/virtualrouters/${service} --query virtualRouter.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}") || err "Unable to create/update virtual router" "$?"
    print "--> ${uid}"
}

update_virtual_router() {
    service=$1
    cmd=( aws --region ${AWS_REGION} $MESHCMD update-virtual-router --mesh-name ${MESH_NAME} --cli-input-json file:///${DIR}/config/virtualrouters/${service} --query virtualRouter.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}" 2>/dev/null) || create_virtual_router ${service}
    print "--> ${uid}"
}

configure_virtual_routers() {
    print "Creating/updating virtual routers"
    print "================================="
    for service in $(ls ${DIR}/config/virtualrouters); do
        update_virtual_router ${service}
    done
}

create_route() {
    service=$1
    cmd=( aws --region ${AWS_REGION} $MESHCMD create-route --mesh-name ${MESH_NAME} --cli-input-json file:///${DIR}/config/routes/${service} --query route.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}") || err "Unable to create/update route" "$?"
    print "--> ${uid}"
}

update_route() {
    service=$1
    cmd=( aws --region ${AWS_REGION} $MESHCMD update-route --mesh-name ${MESH_NAME} --cli-input-json file:///${DIR}/config/routes/${service} --query route.metadata.uid --output text )
    print "${cmd[@]}"
    uid=$("${cmd[@]}" 2>/dev/null) || create_route ${service}
    print "--> ${uid}"
}

configure_routes() {
    print "Creating/updating routes"
    print "========================"
    for service in $(ls ${DIR}/config/routes); do
        update_route ${service}
    done
}

main() {
    sanity_check
    configure_virtual_nodes
    configure_virtual_routers
    configure_routes
}

main
