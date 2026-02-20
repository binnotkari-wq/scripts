#!/bin/bash

# Répertoire contenant les fichiers HTML
DIR="./"  # modifie ici le chemin si besoin

# Parcours tous les fichiers .html dans le répertoire
for f in "$DIR"/*.html; do
  # Vérifie que le fichier existe (au cas où aucun .html)
  [ -e "$f" ] || continue
  
  # Nom du fichier sans extension
  base="${f%.html}"
  
  # Conversion avec pandoc
  pandoc "$f" -f html -t markdown -o "${base}.md"
  
  echo "Converti : $f --> ${base}.md"
done
