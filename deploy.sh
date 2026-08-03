#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
NAMESPACE="${1:-openchamber}"
DOMAIN="${2:-$(grep '^DOMAIN=' .env 2>/dev/null | cut -d= -f2)}"

if [ -z "$DOMAIN" ]; then
  echo "Error: DOMAIN not set. Add DOMAIN=<your-domain> to .env or pass as second argument." >&2
  exit 1
fi

kubectl create secret generic openchamber-secrets \
  --namespace "$NAMESPACE" \
  --from-env-file .env \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install openchamber ./chart \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.host="$DOMAIN"
