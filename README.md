# CreateBitnamiKorifiService.sh

Intro:

Using Kubernetes with Tanzu Platform via a cloud-foundry "cf" abstraction is supported via the korifi controller, but there's not native korifi cloud foundry marketplace.

The tanzu bitnami services operator and services toolkit allows for k8s native services to be dynamically provisioned via "ResourceClaim" construct

How can these dynamically created services be easily exposed to the applications deployed using the cloud-foundry/korifi abstraction

This script will generate a 'cf service instance' in the appropriate k8s namespace such that the cloud foundry api can see it and allow for cf pushed applications to 'bind' directly to bitnami operator provisioned services. 

No need to extract and re-inject the service connection secrets.


##


Script takes 3 inputs
- K8s namespace in which a ResourceClaim has been created - e.g. default
- CF space name in which korifi service connection is required - e.g. DemoSpace
- ResourceClaim / Service name - e.g. postgres1


##

Script will create a Carvel SecretExport from the namespace hosting the ResourceClaim

Script will create a Carvel SecretImport into the k8s namespace that underpins the cf space

Script will create CF service (cfServiceInstance) allowing for cf pushed apps to bind to the bitnami resource
