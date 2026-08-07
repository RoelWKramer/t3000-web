#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

TAG=$(git rev-parse --short HEAD)
if ! git diff-index --quiet HEAD --; then
  TAG="${TAG}-edited"
fi
echo "$TAG" > .build-tag

docker build --platform linux/amd64 \
  -t rg.nl-ams.scw.cloud/t3000-dev/openchamber:latest \
  -t "rg.nl-ams.scw.cloud/t3000-dev/openchamber:$TAG" \
  ./openchamber
