#!/bin/sh
set -e

if [ -n "$GITHUB_PAT" ]; then
  git config --global credential.helper store
  echo "https://x-access-token:${GITHUB_PAT}@github.com" > /root/.git-credentials
  git config --global user.email "opencode@local"
  git config --global user.name "OpenCode"
fi

exec opencode serve
