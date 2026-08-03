#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
docker build --platform linux/amd64 -t rg.nl-ams.scw.cloud/t3000-dev/openchamber:latest ./openchamber
