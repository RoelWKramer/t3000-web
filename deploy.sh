#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <registry-namespace> [environment]"
    echo "Example: $0 rg.nl-ams.scw.cloud/t3000-dev dev"
    echo ""
    echo "Prerequisites:"
    echo "  - kubectl configured with cluster context"
    echo "  - Secret 'openchamber-secrets' created in the namespace"
    echo "    kubectl create secret generic openchamber-secrets \\"
    echo "      --from-literal=OPENCODE_GO_API_KEY=sk-... \\"
    echo "      --from-literal=GITHUB_PAT=ghp_... \\"
    echo "      --from-literal=OPENCHAMBER_UI_PASSWORD=..."
    exit 1
fi

REGISTRY="$1"
ENVIRONMENT="${2:-dev}"
REGISTRY_SERVER=$(echo "$REGISTRY" | cut -d/ -f1)
IMAGE_NAME="openchamber"
GIT_SHA=$(git rev-parse --short HEAD)
RELEASE_NAME="openchamber"
NAMESPACE="openchamber"
PULL_SECRET_NAME="t3000-${ENVIRONMENT}-imagepullsecret"
APP_NAME="t3000-${ENVIRONMENT}-imagepullsecret"

APP_ID=$(scw iam application list -o json | jq -r ".[] | select(.name==\"${APP_NAME}\") | .id")
if [ -z "$APP_ID" ]; then
    echo "IAM application '${APP_NAME}' not found."
    exit 1
fi

echo "Deleting old keys"
scw iam api-key list -o json | jq -r ".[] | select(.application_id==\"${APP_ID}\") | .access_key" | while read -r access_key; do
    scw iam api-key delete "$access_key" -y 2>/dev/null || true
done

echo "Creating new key for $APP_ID"
KEY_JSON=$(scw iam api-key create application-id="$APP_ID" -o json)
echo $KEY_JSON
ACCESS_KEY=$(echo "$KEY_JSON" | jq -r '.access_key')
SECRET_KEY=$(echo "$KEY_JSON" | jq -r '.secret_key')

echo "Created fresh pull credentials (access key: ${ACCESS_KEY})"

# Create namespace and pull secret
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - &>/dev/null
kubectl create secret docker-registry "${PULL_SECRET_NAME}" \
    -n "${NAMESPACE}" \
    --docker-server="${REGISTRY_SERVER}" \
    --docker-username="nlexternal" \
    --docker-password="${SECRET_KEY}" \
    --dry-run=client -o yaml | kubectl apply -f - &>/dev/null

echo "Deploying ${REGISTRY}/${IMAGE_NAME}:${GIT_SHA}..."

helm upgrade --install "${RELEASE_NAME}" ./chart \
    --namespace "${NAMESPACE}" \
    --set image.repository="${REGISTRY}/${IMAGE_NAME}" \
    --set image.tag="${GIT_SHA}" \
    --set imagePullSecret="${PULL_SECRET_NAME}"

echo ""
echo "Deployment complete."
echo ""
echo "Access the service:"
echo "  kubectl port-forward svc/${RELEASE_NAME} 3000:3000 -n ${NAMESPACE}"
echo "  Then open http://localhost:3000"
