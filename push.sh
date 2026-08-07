#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f .build-tag ]; then
  echo "Error: .build-tag not found. Run ./build.sh first." >&2
  exit 1
fi

TAG=$(cat .build-tag)

docker push rg.nl-ams.scw.cloud/t3000-dev/openchamber:latest
docker push "rg.nl-ams.scw.cloud/t3000-dev/openchamber:$TAG"
