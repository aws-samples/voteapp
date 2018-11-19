#!/bin/bash

set -ex

action=${1:-"update-mesh"}

aws --profile ${AWS_PROFILE} --region ${AWS_REGION} \
    lattice ${action} \
    --mesh-name ${MESH_NAME}
