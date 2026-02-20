#!/bin/bash
# Script: telecharger_paquets.sh
# Usage: ./telecharger_paquets.sh nom1 nom2 ...

# Répertoire de destination
DEST="$HOME/offline-packages"
mkdir -p "$DEST"

# Créer une liste de paquets déjà disponibles sur le DVD (cache APT local)
AVAILABLE=$(mktemp)
apt-cache dumpavail | grep '^Package:' | cut -d' ' -f2 > "$AVAILABLE"

# Boucle sur les paquets donnés en argument
for pkg in "$@"; do
    echo "Traitement du paquet : $pkg"

    # Récupérer toutes les dépendances récursivement
    for dep in $(apt-rdepends "$pkg" 2>/dev/null | grep -v "^ " | grep -v "^PreDepends:" | grep -v "^Depends:" | sort -u); do
        # Vérifie si le paquet est déjà sur le DVD
        if ! grep -qx "$dep" "$AVAILABLE"; then
            echo "  => Téléchargement de $dep"
            apt download "$dep" -o Dir::Cache="$DEST" -o Dir::Cache::archives="$DEST"
        else
            echo "  => $dep déjà sur le DVD, ignoré"
        fi
    done
done

echo "Tous les paquets ont été téléchargés dans $DEST"

