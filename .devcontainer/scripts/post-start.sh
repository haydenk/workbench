#!/usr/bin/env bash
# Runs on every container start. Keep fast.

if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
  echo ""
  echo "  gh not authenticated — run: gh auth login"
  echo ""
fi
