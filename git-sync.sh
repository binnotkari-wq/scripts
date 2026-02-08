#!/usr/bin/env bash

PARENT_DIR="$HOME/Mes-Donnees/Git"
REPOS=("home-manager" "install-script" "nixos-dotfiles" "scripts" "info_doc" "user-dotfiles")
HOST=$(hostname)

echo "--- Début de la synchronisation sur [$HOST] : $(date) ---"

for repo in "${REPOS[@]}"; do
    TARGET="$PARENT_DIR/$repo"
    if [ -d "$TARGET" ]; then
        cd "$TARGET" || continue
        git fetch origin

        if [[ -n $(git status --porcelain) ]]; then
            git add .
            # Commit avec le nom de la machine
            git commit -m "Auto-sync [$HOST] : $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        git push origin $(git rev-parse --abbrev-ref HEAD) 2>/dev/null
        git pull --rebase origin $(git rev-parse --abbrev-ref HEAD)
    fi
done
