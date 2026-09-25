#!/usr/bin/env bash

set -e

# Dossier cible (par défaut le dossier courant, ou passé en paramètre)
TARGET_DIR="${1:-.}"

echo "🔍 Recherche et remplacement de '$USER' par '\$USER' dans : $TARGET_DIR"
echo "------------------------------------------------------------------"

# Compteur pour le bilan
COUNT=0

# On recherche tous les fichiers .sh dans l'arborescence
while IFS= read -r -d '' file; do
  # Vérification si le terme '$USER' est présent dans le fichier
  if grep -q "$USER" "$file"; then
    echo "✏️  Modification : $file"
    
    # Remplacement de '$USER' par '$USER' (en littéral avec de simples quotes)
    sed -i 's/$USER/\$USER/g' "$file"
    
    COUNT=$((COUNT + 1))
  fi
done < <(find "$TARGET_DIR" -type f -name "*.sh" -print0)

echo "------------------------------------------------------------------"
echo "✅ Opération terminée. $COUNT fichier(s) `.sh` modifié(s)."
