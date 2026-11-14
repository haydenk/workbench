#!/usr/bin/env bash
set -euo pipefail
# Dotfiles are installed after postCreateCommand and before this hook.
# Bootstrap is idempotent: existing tools and shell plugins are reused.
dotfiles_config="${XDG_CONFIG_HOME:-$HOME/.config}"
if command -v zsh >/dev/null 2>&1 && [ -r "$dotfiles_config/zsh/install.zsh" ]; then
  zsh -c 'source "$ZDOTDIR/dotfiles.zsh"; source "$ZDOTDIR/install.zsh"; dotfiles_bootstrap'
  if command -v fish >/dev/null 2>&1 && [ -r "$dotfiles_config/fish/conf.d/install.fish" ]; then
    # Shared CLI tools were installed by the Zsh bootstrap above.
    fish -c 'install_fisher; and install_fish_plugins'
  fi
elif command -v fish >/dev/null 2>&1 && [ -r "$dotfiles_config/fish/conf.d/install.fish" ]; then
  fish -c dotfiles_bootstrap
fi

# GH_PAT is mapped to GITHUB_TOKEN via remoteEnv; authentication stays explicit.
if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
  echo ""
  echo "  gh not authenticated — run: gh auth login"
  echo ""
fi
