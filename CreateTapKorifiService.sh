#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo 'Usage: CreateTapKorifiService.sh [K8S namespace claiming service] [cf space] [bitnami classclaim/service instance name]'
    exit 0
fi

ns=$1
cfSpace=$2
serviceName=$3
pgsecret=$(kubectl -n $ns get classclaims.services.apps.tanzu.vmware.com $serviceName -o json | jq -r .metadata.uid)

cfk8sns=$(cf curl /v3/spaces | jq ".resources[] | select(.name==\"$cfSpace\")" | jq -r .guid)

echo
echo "Creating $serviceName Service Secret-Export from $ns"
cat <<EOF | kubectl apply -f -
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
#!  finalizers:
#!  - fynesy.com/no-delete
  name: $pgsecret
  namespace: $ns
spec:
  toNamespaces:
  - $cfk8sns
EOF
echo
echo "Creating $serviceName Service Secret-Import to $cfSpace K8s namespace: $cfk8sns"
cat <<EOF | kubectl apply -f -
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretImport
metadata:
  name: $pgsecret
  namespace: $cfk8sns
spec:
  fromNamespace: $ns
EOF
echo

echo "Creating $serviceName Korifi user-provided service for cf space $cfSpace"
cat <<EOF | kubectl apply -f -
apiVersion: korifi.cloudfoundry.org/v1alpha1
kind: CFServiceInstance
metadata:
  annotations:
    korifi.cloudfoundry.org/creation-version: v9999.99.99-local.dev
  name: $serviceName
  namespace: $cfk8sns
spec:
  displayName: $serviceName
  secretName: $pgsecret
  type: user-provided
EOF
echo


