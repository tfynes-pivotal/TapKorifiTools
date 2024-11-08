#!/bin/bash
curl -v --request POST http://localhost:28080/api/convert/openapi -H 'Content-Type: application/json' --data-raw "{
  \"service\": {
    \"name\": \"customer-profile\",
    \"namespace\": \"default\"
  },
  \"openapi\": {
    \"location\": \"http://customer-profile.default.svc.cluster.local:8080/api-docs\"
  },
  \"routes\": [
    {
      \"predicates\": [\"Method=GET,POST,DELETE,PATCH\", \"Path=/api/**\"],
      \"filters\":[\"StripPrefix=1\"]
    }
  ]
}"  