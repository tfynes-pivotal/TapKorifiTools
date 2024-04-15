#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo 'Usage: CreateSCGKorifiRouteMapping.sh [scg_mapping_name] [scg_namespace] [scg_instance_name] [scg_route_config_name]'
    exit 0
fi
scg_mapping_name="$1"
scg_namespace="$2"
scg_instance_name="$3"
scg_route_config_name="$4"

# echo scg_mapping_name = $scg_mapping_name
# echo scg_namespace = $scg_namespace
# echo scg_instance_name=$scg_instance_name
# echo scg_route_config_name= $scg_route_config_name

ytt -f ./templates/scg-route-mapping-template.yaml \
--data-value scg_mapping_name=$scg_mapping_name \
--data-value scg_namespace=$scg_namespace \
--data-value scg_instance_name=$scg_instance_name \
--data-value scg_route_config_name=$scg_route_config_name
