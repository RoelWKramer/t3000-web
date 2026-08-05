#!/bin/sh
set -e

echo "=== entrypoint: whoami=$(whoami) id=$(id) HOME=$HOME ==="
# Ensure directories exist (pre-created in Dockerfile, but safe to retry)
mkdir -p "$HOME/.config/openchamber" "$HOME/.local/share/opencode" 2>/dev/null || true
echo "=== entrypoint: after mkdir ==="

if [ -n "$GITHUB_PAT" ]; then
  git config --global credential.helper store
  echo "https://x-access-token:${GITHUB_PAT}@github.com" > "$HOME/.git-credentials"
  git config --global user.email "opencode@local"
  git config --global user.name "OpenCode"
fi

AUTH_FILE="$HOME/.local/share/opencode/auth.json"
echo '{}' > "$AUTH_FILE"

# Opencode-go
if [ -n "$OPENCODE_GO_API_KEY" ]; then
  tmp=$(mktemp)
  jq --arg key "$OPENCODE_GO_API_KEY" '. * {"opencode-go": {"type": "api", "key": $key}}' "$AUTH_FILE" > "$tmp" && mv "$tmp" "$AUTH_FILE"
fi

# Opencode (Zen)
if [ -n "$OPENCODE_API_KEY" ]; then
  tmp=$(mktemp)
  jq --arg key "$OPENCODE_API_KEY" '. * {"opencode": {"type": "api", "key": $key}}' "$AUTH_FILE" > "$tmp" && mv "$tmp" "$AUTH_FILE"
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
