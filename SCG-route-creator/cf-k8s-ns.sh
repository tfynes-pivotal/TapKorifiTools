if [[ $# -eq 0 ]] ; then
    echo 'Usage: cf-k8s-ns [cf_space]'
    exit 1
fi
cf_space=$1
cf_space_guid=$(cf curl /v3/spaces | jq -r ".resources[] | select(.name==\"$cf_space\")" | jq -r .guid)
echo -n "$cf_space_guid"

