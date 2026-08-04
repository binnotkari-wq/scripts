#!/usr/bin/env bash
# Mise à jour Homebrew (utilisateur uniquement, jamais en root).
set -euo pipefail

if ! command -v brew &>/dev/null; then
    echo "brew non installé, rien à faire."
    exit 0
fi

echo "brew update"
brew update

echo "brew outdated (aperçu)"
brew outdated || true

echo "brew upgrade"
brew upgrade

echo "brew autoremove"
brew autoremove

echo "brew cleanup"
brew cleanup --prune=all

echo "brew doctor (diagnostic, non bloquant)"
brew doctor || true

echo "Mise à jour des flatpaks utilisateur"
flatpak update --user --assumeyes --noninteractive || true
