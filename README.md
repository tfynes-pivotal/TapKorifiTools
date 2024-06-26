# CreateTapKorifiService.sh

## Intro:

Using Kubernetes with Tanzu Platform via a cloudfoundry "cf" abstraction is supported via the korifi controller, but there's no native korifi cloudfoundry marketplace.

TAP for Kubernetes ships however with a TAP (bitnami) services operator providing kubernetes hosted services provisioned on demand (postgres, mysql, rabbitmq, redis, kafka)

So can korifi leverage the TAP native operator as a marketplace?

This script will link the tanzu service secret to the cf layer, generating a 'cf service instance' in the appropriate k8s namespace such that the cloud foundry api can see and bind directly to tanzu provisioned services.

No need to extract and re-inject the service connection secrets!


## Usage:
Script takes 3 inputs
- K8s namespace in which a Tanzu Data Service has been created - e.g. default
- CF space name in which korifi service connection is required - e.g. DemoSpace
- ClassClaim / Service name - e.g. postgres1

---

## Known issue:

TAP clusters are deleting the underlying secretExport every 10 minutes. This script thus needs to be re-run if restarting korifi pushed applications to refresh the service binding after this period of time has elapsed.
UPDATE: Issue remediated / fixed in TAP 1.10

---

## Worked Example: 
- View services marketplace offerings
- Provision postgres database
- Link generated secret to cf/korifi abstraction layer
- Deploy spring-petclinic demo app, binding it to the tanzu postgres service **



1. View Claimable Services in Tanzu enabled Cluster (a korifi/tap alternative to "cf marketplace")
```
tanzu services classes list
  NAME                  DESCRIPTION
  kafka-unmanaged       Kafka by Bitnami
  mongodb-unmanaged     MongoDB by Bitnami
  mysql-unmanaged       MySQL by Bitnami
  postgresql-unmanaged  PostgreSQL by Bitnami
  rabbitmq-unmanaged    RabbitMQ by Bitnami
  redis-unmanaged       Redis by Bitnami
```

2. Create a basic Postgres service using tanzu cli
```
tanzu services class-claim create postgres1 --class postgresql-unmanaged
```


3. Korifi / CF environment (org and space) targetted on same k8s cluster
```
cf target
API endpoint:   https://api.a4.fynesy.com
API version:    3.117.0+cf-k8s
user:           tas-admin
org:            DemoOrg
space:          DemoSpace
```

4. Link Tanzu native service to cf service instance representation
```
./CreateTapKorifiService.sh default DemoSpace postgres1
Creating postgres1 Service Secret-Export from default
  secretexport.secretgen.carvel.dev/6de1a2bd-eec8-4159-97c2-62b28a3af8eb created
Creating postgres1 Service Secret-Import to DemoSpace K8s namespace: cf-space-41f93f77-d2ac-48c0-8f0b-1a1c8a020a59
  secretimport.secretgen.carvel.dev/6de1a2bd-eec8-4159-97c2-62b28a3af8eb created
Creating postgres1 Korifi user-provided service for cf space DemoSpace
  cfserviceinstance.korifi.cloudfoundry.org/postgres1 created
```

5. Confirm service now exists for cf apps
```
cf services
Getting service instances in org DemoOrg / space DemoSpace as tas-admin...

name        offering        plan   bound apps   last operation     broker   upgrade available
postgres1   user-provided                       create succeeded
```

6. Validate service by deploying spring petclinic demo app and binding it to new postgres db service instance
```
cf push cf-petclinic -p ~/Downloads/spring-petclinic/target/spring-petclinic-3.2.0-SNAPSHOT.jar --no-start
cf restage cf-petclinic
```


---

What's happening 'under the covers'

Script creates a Carvel SecretExport from the namespace hosting the ClassClaim

Script creates a Carvel SecretImport into the k8s namespace that underpins the cf space

Script creates CF service (cfServiceInstance) allowing for cf pushed apps to bind to the bitnami resource


Limitations:
- Unique cf spaces names required (for now)
- Clusters with large (20+) orgs/spaces could break the script as cf api pagination walking not implemented.

---

## SCG Route Creator

While korifi doesn't formally support 'internal domains', 'cf-push' deployed services can be accesed at the k8s 
layer if you're aware of the name and namespace. These can be found from the cf api by curling space and app endpoints.
```
CreateSCGKorifiRouteConfig.sh
```
generates an SCG route-config, populating the target service and namespace accordingly. Run this script, direct output to file 
and apply to k8s cluster
```
CreateSCGKorifiRouteMapping.sh 
```
simply creates a corresponding SCG route to gateway-instance mapping CR which should also be applied to the cluster.


## Gateway Route Configuration Autogeneration from OpenAPI docs

1. Deploy customer-profile java rest service with openapi docs exposed on /apidocs context
```
tanzu services class-claim create customer-database --class postgresql-unmanaged
./CreateTapKorifiService.sh default DemoSpace customer-database

cf push customer-profile -p target/customer-profile-0.0.1-SNAPSHOT.jar --no-start
cf bind-service customer-profile customer-database
cf start customer-profile
```

2. Switch app to running locally off a cluster.local internal domain
```
cf create-shared-domain cluster.local
cf map-route customer-profile cluster.local --hostname customer-profile
cf unmap-route customer-profile a5.fynesy.com
```

3. Port forward localhost:18080 to spring-cloud-gateway operator port 8080 to access openapi->routeConfig transformer service
```
kubectl -n spring-cloud-gateway port-forward deployment/scg-operator 18080:8080
```

4. Run 
```
cf-service-2-routeconfig.sh [internal fqdn] [cf-space-name]
```
to generate scg route-config. save to file and apply to cluster.
E.g.

```
./cf-service-2-routeconfig.sh customer-profile.cluster.local DemoSpace > rc1.json
kubectl apply -f ./rc1.json
```

5. Create scg mapping from this generated scg-route-config to existing SCG instance. Helper script 'cf-k8s-svc.sh' returns route-config name (same as target internal k8s service for customer-profile) - use as input
```
./CreateSCGKorifiRouteMapping.sh m1 default tdemo-gateway $(./cf-k8s-svc.sh customer-profile.cluster.local) > m1.yaml
kubectl apply -f ./m1.yaml
```
