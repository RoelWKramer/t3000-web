#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
NAMESPACE="${1:-openchamber}"

kubectl create secret generic openchamber-secrets \
  --namespace "$NAMESPACE" \
  --from-env-file .env \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install openchamber ./chart \
  --namespace "$NAMESPACE" \
  --create-namespace
