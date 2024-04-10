# CreateBitnamiKorifiService.sh

Intro:

Using Kubernetes with Tanzu Platform via a cloud-foundry "cf" abstraction is supported via the korifi controller, but there's not native korifi cloud foundry marketplace.

The tanzu bitnami services operator and services toolkit allows for k8s native services to be dynamically provisioned via "ClassClaim" construct

How can these dynamically created services be easily exposed to the applications deployed using the cloud-foundry/korifi abstraction

This script will generate a 'cf service instance' in the appropriate k8s namespace such that the cloud foundry api can see it and allow for cf pushed applications to 'bind' directly to bitnami operator provisioned services. 

No need to extract and re-inject the service connection secrets.


##


Script takes 3 inputs
- K8s namespace in which a ClassClaim has been created - e.g. default
- CF space name in which korifi service connection is required - e.g. DemoSpace
- ClassClaim / Service name - e.g. postgres1

##

Script creates a Carvel SecretExport from the namespace hosting the ClassClaim

Script creates a Carvel SecretImport into the k8s namespace that underpins the cf space

Script creates CF service (cfServiceInstance) allowing for cf pushed apps to bind to the bitnami resource

##

Sample Postgres db provisioned into default NS via ClassClaim
```
apiVersion: services.apps.tanzu.vmware.com/v1alpha1
kind: ClassClaim
metadata:
  annotations:
    classclaims.services.apps.tanzu.vmware.com/xrd-name: xpostgresqlinstances.bitnami.database.tanzu.vmware.com
  finalizers:
  - classclaims.services.apps.tanzu.vmware.com/provision-finalizer
  name: postgres1
  namespace: default
spec:
  classRef:
    name: postgresql-unmanaged
  parameters: {}
```

ClassClaim / PostgresDB instance in default k8s namespace
```
kubectl get classclaims.services.apps.tanzu.vmware.com
NAME        READY   REASON   CLASSREF
postgres1   True    Ready    postgresql-unmanaged
```

Empty Korifi / CF environment (org and space) targetted on same k8s cluster
```
cf target
API endpoint:   https://api.a4.fynesy.com
API version:    3.117.0+cf-k8s
user:           tas-admin
org:            DemoOrg
space:          DemoSpace
```
Create link from Default-NS ClassClaim for PostgresDB instance to CF 'space' - note this manifests in a guid-named cf-space-*** in the k8s cluster
```
(base) tfynes2JGH5:TapKorifiTools thomasfynes$ ./CreateBitnamiKorifiService.sh default DemoSpace postgres1
Creating postgres1 Service Secret-Export from default
secretexport.secretgen.carvel.dev/6de1a2bd-eec8-4159-97c2-62b28a3af8eb created

Creating postgres1 Service Secret-Import to DemoSpace K8s namespace: cf-space-41f93f77-d2ac-48c0-8f0b-1a1c8a020a59
secretimport.secretgen.carvel.dev/6de1a2bd-eec8-4159-97c2-62b28a3af8eb created

Creating postgres1 Korifi user-provided service for cf space DemoSpace
cfserviceinstance.korifi.cloudfoundry.org/postgres1 created
```
Confirm service now exists for cf apps
```
cf services
Getting service instances in org DemoOrg / space DemoSpace as tas-admin...

name        offering        plan   bound apps   last operation     broker   upgrade available
postgres1   user-provided                       create succeeded
```

Validate service by deploying spring petclinic demo app and binding it to new postgres db service instance
```
cf push cf-petclinic -p ~/Downloads/spring-petclinic/target/spring-petclinic-3.2.0-SNAPSHOT.jar --no-start
cf restage cf-petclinic
```

