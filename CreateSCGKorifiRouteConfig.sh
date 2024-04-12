#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo 'Usage: CreateSCGKorifiRouteConfig.sh [scg_route_config_name] [scg_namespace] [cf_target_route_fqdn] [cf_space] [scg_route_predicate]'
    exit 0
fi


#[scg_route_config_name] 
#[scg_namespace] 
#[cf_target_route_fqdn] 
#[cf_space] 
#[scg_route_predicate]

scg_route_config_name="$1"
scg_namespace="$2"
cf_target_route_fqdn="$3"
cf_target_route_fqdn_guid=$(cf curl /v3/routes | jq -r ".resources[] | select(.url==\"$cf_target_route_fqdn\")" | jq -r .destinations[0].guid)

cf_space="$4"
cf_space_guid=$(cf curl /v3/spaces | jq -r ".resources[] | select(.name==\"$cf_space\")" | jq -r .guid)

scg_route_predicate="$5"




echo scg_route_config_name = $scg_route_config_name
echo scg_namespace = $scg_namespace
echo cf_target_route_fqdn  = $cf_target_route_fqdn
echo cf_target_route_fqdn_guid  = $cf_target_route_fqdn_guid
echo cf_space = $cf_space
echo cf_space_guid = $cf_space_guid
echo scg_route_predicate = $scg_route_predicate

ytt -f ./templates/scg-cf-route-config-template.yaml \
--data-value scg_route_config_name=$scg_route_config_name \
--data-value scg_namespace=$scg_namespace --data-value cf_target_route_fqdn=$cf_target_route_fqdn \
--data-value cf_target_route_fqdn_guid=$cf_target_route_fqdn_guid \
--data-value cf_space=$cf_space \
--data-value cf_space_guid=$cf_space_guid \
--data-value scg_route_predicate=$scg_route_predicate
