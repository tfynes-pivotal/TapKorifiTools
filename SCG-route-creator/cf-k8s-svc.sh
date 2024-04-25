if [[ $# -eq 0 ]] ; then
    echo 'Usage: cf-k8s-svc [cf_route_fqdn]'
    exit 1
fi
cf_route_fqdn=$1
cf_route_fqdn_guid=$(cf curl /v3/routes | jq -r ".resources[] | select(.url==\"$cf_route_fqdn\")" | jq -r .destinations[0].guid)
cf_route_k8s_service="s-$cf_route_fqdn_guid"
echo -n "$cf_route_k8s_service"