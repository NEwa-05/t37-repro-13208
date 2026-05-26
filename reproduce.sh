#!/bin/bash

function float_to_int() { 
  echo $1 | cut -d. -f1
}

export startTime=$(float_to_int $(date +%s.%N))

function rolling {
kubectl rollout restart -n whoami deploy whoami
ATTEMPTS=0
ROLLOUT_STATUS_CMD="kubectl rollout status -n whoami deploy whoami"
until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
  $ROLLOUT_STATUS_CMD
  ATTEMPTS=$((attempts + 1))
  sleep 10
done
}

function checksvcip {
kubectl -n whoami get endpointslices \
  -l kubernetes.io/service-name=whoami \
  -o json \
  | jq -r '.items[].endpoints[] | select(.conditions.ready==true) | .addresses[]' \
  | sort -u > svcepips.txt
}

function checkstrsvcip {
curl -s https://dashboard.localdemo.mageekbox.eu/api/http/services | jq '.[] | select(.name | startswith("whoami-whoami")) | .loadBalancer.servers[].url'  \
  | sed -E 's/.*http:\/\/([0-9.]+):[0-9]+.*/\1/' \
  | sort -u > traefik-ipused.txt
}

function checktrlogs {
    export checkTime=$(float_to_int $(date +%s.%N))
    export diffTime=$(echo $(( (checkTime - startTime) )))
    kubectl -n traefik logs -l app.kubernetes.io/instance=traefik-traefik --since=${diffTime}s \
  | grep 'whoami' \
  | grep -oE '"url":"http://[0-9.]+:[0-9]+"' \
  | sed -E 's/.*http:\/\/([0-9.]+):[0-9]+.*/\1/' \
  | sort -u > trlog-ipused.txt
}

rolling
checksvcip
sleep 2
checkstrsvcip
checktrlogs
comm -23 traefik-ipused.txt svcepips.txt
comm -23 trlog-ipused.txt svcepips.txt
