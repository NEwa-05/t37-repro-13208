# t37-repro-13208

Reproduction configuration for Traefik issue 13208

## Create cluster

```shell
sudo k3d cluster create k8s-370 --port 80:80@loadbalancer --port 443:443@loadbalancer --k3s-arg "--disable=traefik@server:0"
k3d kubeconfig get k8s-370 > .kubeconfig
chmod 600 .kubeconfig
```

## load variables

```shell
source .env
```

## Deploy Traefik

### Create Traefik NS

```bash
kubectl create ns traefik
```

### Create secret from cert file

```bash
kubectl create secret tls wildcard-mageekbox --namespace traefik --cert=.lego/certificates/${CLUSTERNAME}.${DOMAINNAME}.crt --key=.lego/certificates/${CLUSTERNAME}.${DOMAINNAME}.key
```

### Install with Helm

```shell
helm upgrade --install traefik traefik/traefik --create-namespace --namespace traefik --values ./traefik/values.yaml
```

### Add Dashboard

```shell
envsubst < ./traefik/dashboard.yaml | kubectl apply -f -
```

## deploy app

```shell
envsubst < ./whoami/whoami.yaml | kubectl apply -f -
```

## test the issue

```shell
./reproduce.sh
```
