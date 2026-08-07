#!/usr/bin/env bash
set -euo pipefail

CHARTS_DIR="${CHARTS_DIR:-/opt/opencode/charts}"

NAMESPACE="${NAMESPACE:-default}"
APP_NAME="${APP_NAME:-$(basename "$(pwd)")}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
HOST="${HOST:-$NAMESPACE.apps.vynder.net}"
REPLICAS="${REPLICAS:-1}"
REGISTRY="${REGISTRY:-rg.nl-ams.scw.cloud}"
PUSH_NS="${PUSH_NS:-t3000-dev}"
INGRESS_CLASS="${INGRESS_CLASS:-nginx}"
DOCKERFILE="${1:-Dockerfile}"

BUILD_CONTEXT_CONFIGMAP="$APP_NAME-build-context"
IMAGE_REPO="$REGISTRY/$PUSH_NS/$NAMESPACE/$APP_NAME"

usage() {
  echo "Usage: $(basename "$0") [Dockerfile]"
  echo
  echo "Environment variables:"
  echo "  NAMESPACE   Kubernetes namespace (default: default)"
  echo "  APP_NAME    App name (default: current directory name)"
  echo "  IMAGE_TAG   Image tag (default: latest)"
  echo "  HOST        Ingress host (default: \$NAMESPACE.apps.vynder.net)"
  echo "  REPLICAS    Deployment replicas (default: 1)"
  echo "  REGISTRY    Container registry (default: rg.nl-ams.scw.cloud)"
  echo "  PUSH_NS     Registry push namespace (default: t3000-dev)"
  exit 1
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
fi

if [ ! -f "$DOCKERFILE" ]; then
  echo "Error: Dockerfile not found at '$DOCKERFILE'" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 1 — Create ConfigMap from Dockerfile
# ---------------------------------------------------------------------------
echo "==> Creating build context ConfigMap: $BUILD_CONTEXT_CONFIGMAP"

kubectl create configmap "$BUILD_CONTEXT_CONFIGMAP" \
  --from-file="Dockerfile=$DOCKERFILE" \
  --namespace "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

# ---------------------------------------------------------------------------
# Step 2 — Launch build Job
# ---------------------------------------------------------------------------
echo "==> Launching build job for $APP_NAME"

helm template "$APP_NAME-build" "$CHARTS_DIR/kaniko-build" \
  --set tenant="$NAMESPACE" \
  --set app="$APP_NAME" \
  --set tag="$IMAGE_TAG" \
  --set registry.endpoint="$REGISTRY" \
  --set registry.pushNamespace="$PUSH_NS" \
  --set build.contextConfigMap="$BUILD_CONTEXT_CONFIGMAP" \
  | kubectl apply -f -

# ---------------------------------------------------------------------------
# Step 3 — Wait for build and show logs
# ---------------------------------------------------------------------------
BUILD_JOB="job/build-$APP_NAME"
echo "==> Waiting for $BUILD_JOB to complete..."

kubectl wait --for=condition=complete "$BUILD_JOB" \
  -n "$NAMESPACE" --timeout=120s

echo "==> Build logs:"
BUILD_POD=$(kubectl get pods -n "$NAMESPACE" -l "app=$APP_NAME" -o name | tail -1)
kubectl logs -n "$NAMESPACE" "$BUILD_POD" --tail=20

# ---------------------------------------------------------------------------
# Step 4 — Deploy the app
# ---------------------------------------------------------------------------
echo "==> Deploying $APP_NAME in namespace $NAMESPACE"

helm template "$APP_NAME" "$CHARTS_DIR/web-app" \
  --namespace "$NAMESPACE" \
  --set "image.repository=$IMAGE_REPO" \
  --set "image.tag=$IMAGE_TAG" \
  --set "host=$HOST" \
  --set "replicaCount=$REPLICAS" \
  --set "ingressClassName=$INGRESS_CLASS" \
  | kubectl apply -f -

# ---------------------------------------------------------------------------
# Step 5 — Done
# ---------------------------------------------------------------------------
echo "==> $APP_NAME deployed at https://$HOST"
