#!/bin/sh
set -e

if [ -n "$GITHUB_PAT" ]; then
  git config --global credential.helper store
  echo "https://x-access-token:${GITHUB_PAT}@github.com" > /home/openchamber/.git-credentials
  git config --global user.email "opencode@local"
  git config --global user.name "OpenCode"
fi

if [ -n "$OPENCODE_GO_API_KEY" ]; then
  mkdir -p /home/openchamber/.local/share/opencode
  cat > /home/openchamber/.local/share/opencode/auth.json <<EOF
{
  "opencode-go": {
    "type": "api",
    "key": "${OPENCODE_GO_API_KEY}"
  }
}
EOF
fi

exec openchamber serve --port 3000 --host 0.0.0.0 --foreground
