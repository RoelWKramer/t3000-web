#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
NAMESPACE="${1:-openchamber}"
DOMAIN="${2:-$(grep '^DOMAIN=' .env 2>/dev/null | cut -d= -f2)}"
IP="${3:-$(grep '^IP=' .env 2>/dev/null | cut -d= -f2)}"

if [ -z "$DOMAIN" ]; then
  echo "Error: DOMAIN not set. Add DOMAIN=<your-domain> to .env or pass as second argument." >&2
  exit 1
fi

if [ -z "$IP" ]; then
  echo "Error: IP not set. Add IP=<your-public-ip> to .env or pass as third argument." >&2
  exit 1
fi

TLS_CERT=$(openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /dev/stdout -out /dev/stdout \
  -subj "/CN=$DOMAIN" 2>/dev/null)
TLS_KEY=$(echo "$TLS_CERT" | openssl rsa -out /dev/stdout 2>/dev/null)
TLS_CRT=$(echo "$TLS_CERT" | openssl x509 -out /dev/stdout 2>/dev/null)

kubectl create secret tls openchamber-tls \
  --namespace "$NAMESPACE" \
  --cert=<(echo "$TLS_CRT") \
  --key=<(echo "$TLS_KEY") \
  --dry-run=client -o yaml | kubectl apply -f -

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
  --set-string "ingress.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range=$IP"
