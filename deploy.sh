#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f .build-tag ]; then
  echo "Error: .build-tag not found. Run ./build.sh first." >&2
  exit 1
fi

TAG=$(cat .build-tag)

source_env() {
  local key="$1"
  grep "^$key=" .env 2>/dev/null | cut -d= -f2- || true
}

NAMESPACE="${NAMESPACE:-$(source_env NAMESPACE)}"
BASE_DOMAIN="${BASE_DOMAIN:-$(source_env BASE_DOMAIN)}"
IP_ALLOW="${IP_ALLOW:-$(source_env IP_ALLOW)}"

if [ -z "$NAMESPACE" ]; then
  echo "Error: NAMESPACE not set in .env" >&2
  exit 1
fi

if [ -z "$BASE_DOMAIN" ]; then
  echo "Error: BASE_DOMAIN not set in .env" >&2
  exit 1
fi

if [ -z "$IP_ALLOW" ]; then
  echo "Error: IP_ALLOW not set in .env (comma-separated CIDRs, e.g. 1.2.3.4/32,10.0.0.0/8)" >&2
  exit 1
fi

to_millis() {
  local val="$1"
  if [[ "$val" == *m ]]; then
    echo "${val%m}"
  elif [[ "$val" =~ ^[0-9]+$ ]]; then
    echo $(( val * 1000 ))
  else
    echo 0
  fi
}

to_megs() {
  local val="$1"
  if [[ "$val" == *Gi ]]; then
    echo $(( ${val%Gi} * 1024 ))
  elif [[ "$val" == *Mi ]]; then
    echo "${val%Mi}"
  elif [[ "$val" == *Ki ]]; then
    echo $(( ${val%Ki} / 1024 ))
  elif [[ "$val" =~ ^[0-9]+$ ]]; then
    echo $(( val / 1048576 ))
  else
    echo 0
  fi
}

POD_CPU_LIMIT=1000
POD_MEM_LIMIT=1536

QUOTA_CPU_USED=$(kubectl get resourcequota tenant-quota -n "$NAMESPACE" \
  -o jsonpath='{.status.used.limits\.cpu}' 2>/dev/null || echo "")
QUOTA_CPU_HARD=$(kubectl get resourcequota tenant-quota -n "$NAMESPACE" \
  -o jsonpath='{.status.hard.limits\.cpu}' 2>/dev/null || echo "")

QUOTA_MEM_USED=$(kubectl get resourcequota tenant-quota -n "$NAMESPACE" \
  -o jsonpath='{.status.used.limits\.memory}' 2>/dev/null || echo "")
QUOTA_MEM_HARD=$(kubectl get resourcequota tenant-quota -n "$NAMESPACE" \
  -o jsonpath='{.status.hard.limits\.memory}' 2>/dev/null || echo "")

if [ -n "$QUOTA_CPU_HARD" ]; then
  CPU_USED=$(to_millis "$QUOTA_CPU_USED")
  CPU_HARD=$(to_millis "$QUOTA_CPU_HARD")
  CPU_FREE=$(( CPU_HARD - CPU_USED ))
  if [ "$CPU_FREE" -lt "$POD_CPU_LIMIT" ]; then
    echo "Error: Not enough CPU quota. Pod needs ${POD_CPU_LIMIT}m, only ${CPU_FREE}m free." >&2
    echo "  Quota usage: ${QUOTA_CPU_USED} / ${QUOTA_CPU_HARD}" >&2
    exit 1
  fi
fi

if [ -n "$QUOTA_MEM_HARD" ]; then
  MEM_USED=$(to_megs "$QUOTA_MEM_USED")
  MEM_HARD=$(to_megs "$QUOTA_MEM_HARD")
  MEM_FREE=$(( MEM_HARD - MEM_USED ))
  if [ "$MEM_FREE" -lt "$POD_MEM_LIMIT" ]; then
    echo "Error: Not enough memory quota. Pod needs ${POD_MEM_LIMIT}Mi, only ${MEM_FREE}Mi free." >&2
    echo "  Quota usage: ${QUOTA_MEM_USED} / ${QUOTA_MEM_HARD}" >&2
    exit 1
  fi
fi

DOMAIN="${NAMESPACE}.${BASE_DOMAIN}"

echo "Deploying to $NAMESPACE on $DOMAIN"
echo "Image tag: $TAG"

kubectl create secret generic openchamber-secrets \
  --namespace "$NAMESPACE" \
  --from-env-file .env \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install openchamber ./chart \
  --namespace "$NAMESPACE" \
  --set image.tag="$TAG" \
  --set ingress.enabled=true \
  --set ingress.host="$DOMAIN" \
  --set ingress.className=nginx \
  --set ingress.tls=true \
  --set imagePullSecret=scw-registry \
  --set-string "ingress.annotations.nginx\.ingress\.kubernetes\.io/force-ssl-redirect=true" \
  --set-string "ingress.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range=$IP_ALLOW"

if [[ "$TAG" == *-edited ]]; then
  echo "Force restarting for -edited tag"
  kubectl rollout restart deployment/openchamber -n "$NAMESPACE"
fi

ROLLOUT_TIMEOUT=90

if ! kubectl rollout status deployment/openchamber -n "$NAMESPACE" --timeout="${ROLLOUT_TIMEOUT}s" --watch 2>&1; then
  echo >&2
  echo "Error: Deployment rollout did not complete within ${ROLLOUT_TIMEOUT}s." >&2
  echo "Recent events:" >&2
  kubectl get events -n "$NAMESPACE" --sort-by=.lastTimestamp \
    | grep -i "openchamber" | grep -iE "failed|exceeded|error|backoff|warning" | tail -10 >&2
  exit 1
fi

echo "Deploy complete."
