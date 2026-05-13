# Local Kubernetes deployment

Image: `ghcr.io/tedkozub/httpbin:latest` (public, no pull secret).

## Prerequisites

`docker`, `kind`, `kubectl`, `envsubst` (`brew install gettext`), `openssl`.

## Create cluster

```sh
kind create cluster --name httpbin
```

## Deploy

```sh
export IMAGE="ghcr.io/tedkozub/httpbin:latest"
export HTTPBIN_SECRET_KEY="$(openssl rand -base64 32)"

for f in k8s/configmap.yaml k8s/secret.yaml k8s/deployment.yaml \
         k8s/service.yaml k8s/hpa.yaml k8s/networkpolicy.yaml; do
  envsubst '${IMAGE} ${HTTPBIN_SECRET_KEY}' < "$f" | kubectl apply -f -
done

kubectl rollout status deployment/httpbin --timeout=120s
```

## Smoke test

```sh
kubectl port-forward svc/httpbin 8080:8080 &
sleep 3
curl -fsS http://localhost:8080/get
```

## Cleanup

```sh
kind delete cluster --name httpbin
```

## Notes

- HPA reports `<unknown>` CPU until `metrics-server` is installed.
- NetworkPolicy is not enforced by kind's default CNI (`kindnet`); install Calico for real enforcement.
