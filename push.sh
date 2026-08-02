#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
docker push rg.nl-ams.scw.cloud/t3000-dev/openchamber:latest
