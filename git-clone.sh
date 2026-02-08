#!/usr/bin/env bash

PARENT_DIR="$HOME/Mes-Donnees/Git"
REPOS=("home-manager" "install-script" "nixos-dotfiles" "scripts" "info_doc" "user-dotfiles")


cd $PARENT_DIR
echo "--- Début de l'importation des repos depuis Github ---"
for repo in "${REPOS[@]}"; do
    git clone https://github.com/binnotkari-wq/$repo.git
done
