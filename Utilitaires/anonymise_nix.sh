#!/usr/bin/env bash

set -e

# Dossier cible (dossier courant par défaut, ou dossier spécifié en argument)
TARGET_DIR="${1:-.}"

echo "🔍 Traitement EXCLUSIF des fichiers .nix dans : $TARGET_DIR"
echo "------------------------------------------------------------------"

COUNT=0

# Recherche ciblée : uniquement les fichiers .nix, en ignorant les dossiers cachés (.git, etc.)
while IFS= read -r -d '' file; do
  if grep -q "benoit" "$file"; then
    echo "✏️  Modification : $file"
    
    # Remplacement de 'benoit' par '@@username@@'
    sed -i 's/benoit/@@username@@/g' "$file"
    
    COUNT=$((COUNT + 1))
  fi
done < <(find "$TARGET_DIR" -path '*/.*' -prune -o -type f -name "*.nix" -print0)

echo "------------------------------------------------------------------"
echo "✅ Opération terminée. $COUNT fichier(s) .nix modifié(s)."
