#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

source_env() {
  local key="$1"
  grep "^$key=" .env 2>/dev/null | cut -d= -f2- || true
}

NAMESPACE="${NAMESPACE:-openchamber}"
DOMAIN="$(source_env DOMAIN)"
IP_ALLOW="$(source_env IP_ALLOW)"

if [ -z "$DOMAIN" ]; then
  echo "Error: DOMAIN not set in .env" >&2
  exit 1
fi

if [ -z "$IP_ALLOW" ]; then
  echo "Error: IP_ALLOW not set in .env (comma-separated CIDRs, e.g. 1.2.3.4/32,10.0.0.0/8)" >&2
  exit 1
fi

kubectl create secret generic openchamber-secrets \
  --namespace "$NAMESPACE" \
  --from-env-file .env \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install openchamber ./chart \
  --namespace "$NAMESPACE" \
  --set ingress.enabled=true \
  --set ingress.host="$DOMAIN" \
  --set ingress.className=nginx \
  --set ingress.tls=true \
  --set imagePullSecret=scw-registry \
  --set-string "ingress.annotations.nginx\.ingress\.kubernetes\.io/force-ssl-redirect=true" \
  --set-string "ingress.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range=$IP_ALLOW"

kubectl rollout restart deployment/openchamber -n "$NAMESPACE"
