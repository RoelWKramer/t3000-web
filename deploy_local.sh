#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
CLUSTER="${1:-t3000}"
NAMESPACE="${2:-openchamber}"

echo "Deploying to $NAMESPACE"

if ! kubectl get secret openchamber-secrets --namespace "$NAMESPACE" &>/dev/null; then
  echo "Creating secrets"
  kubectl create secret generic openchamber-secrets \
    --namespace "$NAMESPACE" \
    --from-env-file .env
fi


k3d image import openchamber:local -c "$CLUSTER"

helm upgrade --install openchamber ./chart \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.repository=openchamber \
  --set image.tag=local \
  --set image.pullPolicy=Never \
  --set ingress.enabled=true \
  --set ingress.host="${NAMESPACE:-openchamber}.localhost"
