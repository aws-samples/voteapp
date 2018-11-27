#!/usr/bin/env bash

set -ex

actions=("$@")

if [ "${#actions[@]}" -eq 0 ]; then
    actions+=("create-mesh")
fi

aws --profile ${AWS_PROFILE} \
    --region ${AWS_REGION} \
    appmesh \
    "${actions[@]}" \
    --mesh-name ${MESH_NAME}
