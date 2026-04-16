#!/usr/bin/env bash
set -euox pipefail
# Runs on every container start. Keep fast.

# Map Codespace secrets (can't start with GITHUB_) to the names gh CLI expects.
export GITHUB_TOKEN="${GH_PAT:-}"

if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
  echo ""
  echo "  gh not authenticated — run: gh auth login"
  echo ""
fi
