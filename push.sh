#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <registry-namespace>"
    echo "Example: $0 rg.nl-ams.scw.cloud/t3000-dev"
    exit 1
fi

REGISTRY="$1"
IMAGE_NAME="openchamber"
GIT_SHA=$(git rev-parse --short HEAD)
IMAGE_TAG="${REGISTRY}/${IMAGE_NAME}:${GIT_SHA}"

echo "Pushing ${IMAGE_TAG}..."
docker push "${IMAGE_TAG}"

echo "Pushing ${REGISTRY}/${IMAGE_NAME}:latest..."
docker push "${REGISTRY}/${IMAGE_NAME}:latest"

echo "Push complete."
