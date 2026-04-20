#!/usr/bin/env bash
set -euo pipefail
# Runs on every container start. Keep fast.
#
# Note: GH_PAT is mapped to GITHUB_TOKEN via `remoteEnv` in devcontainer.json,
# so interactive shells pick it up automatically — no export needed here.

if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
  echo ""
  echo "  gh not authenticated — run: gh auth login"
  echo ""
fi
