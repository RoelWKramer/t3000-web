#!/bin/sh
set -e

echo "=== entrypoint: whoami=$(whoami) id=$(id) HOME=$HOME ==="
ls -laR "$HOME"
# Ensure directories exist (pre-created in Dockerfile, but safe to retry)
mkdir -p "$HOME/.config/openchamber" "$HOME/.local/share/opencode" 2>/dev/null || true
echo "=== entrypoint: after mkdir ==="
ls -laR "$HOME"


if [ -n "$GITHUB_PAT" ]; then
  git config --global credential.helper store
  echo "https://x-access-token:${GITHUB_PAT}@github.com" > "$HOME/.git-credentials"
  git config --global user.email "opencode@local"
  git config --global user.name "OpenCode"
fi

if [ -n "$OPENCODE_GO_API_KEY" ]; then
  cat > "$HOME/.local/share/opencode/auth.json" <<EOF
{
  "opencode-go": {
    "type": "api",
    "key": "${OPENCODE_GO_API_KEY}"
  }
}
EOF
fi

# Set default home and last directory if not already configured
SETTINGS_FILE="$HOME/.config/openchamber/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi
if ! jq -e '.homeDirectory' "$SETTINGS_FILE" >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq --arg dir "$HOME" '.homeDirectory = $dir | .lastDirectory = $dir' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
fi

exec openchamber serve --port 3000 --host 0.0.0.0 --foreground
