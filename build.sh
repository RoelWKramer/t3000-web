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

echo "Building ${IMAGE_TAG}..."
docker build --platform linux/amd64 -t "${IMAGE_TAG}" ./openchamber

echo "Also tagging as ${REGISTRY}/${IMAGE_NAME}:latest..."
docker tag "${IMAGE_TAG}" "${REGISTRY}/${IMAGE_NAME}:latest"

echo "Build complete: ${IMAGE_TAG}"
