#!/usr/bin/env bash
set -euox pipefail

echo "════════════════════════════════════════"
echo "  post-create"
echo "════════════════════════════════════════"

<<<<<<< HEAD
# ── Install fish ──────────────────────────────────────────────────────────────
# Remove the yarn apt source if present — its GPG key is expired and breaks
# apt-get update on older universal images.
# sudo rm -f /etc/apt/sources.list.d/yarn.list
# sudo apt-get update -y -qq
# sudo apt-get install -y -qq fish
||||||| parent of ad70a41 (update base image)
# ── Install fish ──────────────────────────────────────────────────────────────
# Remove the yarn apt source if present — its GPG key is expired and breaks
# apt-get update on older universal images.
sudo rm -f /etc/apt/sources.list.d/yarn.list
sudo apt-get update -y -qq
sudo apt-get install -y -qq fish
=======
# ── APT config ────────────────────────────────────────────────────────────────
echo 'APT::Acquire::Retries "3";' | sudo tee /etc/apt/apt.conf.d/80retries > /dev/null
sudo apt-get update -y -qq

# ── Install fish ──────────────────────────────────────────────────────────────
sudo apt-get install -y -qq fish
>>>>>>> ad70a41 (update base image)

# ── Remove default zsh files from home (ZDOTDIR=~/.config/zsh handles config) ─
rm -f "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zlogin" "$HOME/.zlogout"

# ── Install ghrepo shell functions ───────────────────────────────────────────
SCRIPTS=/workspaces/workbench/.devcontainer/scripts

# zsh — copy to ZSH_CUSTOM dir and source from .zshrc
cp "$SCRIPTS/ghrepo.zsh" "$HOME/.config/zsh/ghrepo.zsh"
if ! grep -q 'ghrepo.zsh' "$HOME/.config/zsh/.zshrc" 2>/dev/null; then
  echo 'source "$HOME/.config/zsh/ghrepo.zsh"' >> "$HOME/.config/zsh/.zshrc"
fi

# fish — copy to conf.d/ (auto-sourced at startup, no config.fish edit needed)
mkdir -p "$HOME/.config/fish/conf.d"
cp "$SCRIPTS/ghrepo.fish" "$HOME/.config/fish/conf.d/ghrepo.fish"

echo ""
echo "✓ post-create complete"
echo "  ghrepo        — fuzzy-clone any repo you have access to"
