#!/usr/bin/env bash

# --- DEPLOIEMENT DE L'ENVIRONNEMENT UTILISATEUR ---
set -e # Arrête le script en cas d'erreur

# On définit le répertoire Git (évite d'exporter si non nécessaire par la suite)
MY_GIT_DIR="$HOME/Mes-Donnees/Git"
export MY_GIT_DIR # (utilisé par git-clone.sh et home-manager.sh)

echo "--- [1/4] Mise en place des repos Git ---"
source ./modules/git-clone.sh 

echo "--- [2/4] Configuration de l'OS ---"

# CAS 2 : SYSTÈME ATOMIC (Fedora Silverblue, etc.)
if grep -qE "silverblue|kinoite|bazzite" /etc/os-release 2>/dev/null; then
    echo "🛡️  Système Atomic détecté..."
    
    # On doit redémarrer le pc après l'execution du script atomic.sh, pour activer la compression btrfs.
    
    # On vérifie si le montage racine (/) a déjà l'option zstd active
    if mount | grep "on / " | grep -q "compress=zstd"; then
        echo "✅ ZSTD est déjà actif, le script atomic.sh a bien été déployé. On continue..."
    else
        echo "⚙️  Configuration de Btrfs (ZSTD) requise..."
        source ./modules/atomic.sh
        echo "-------------------------------------------------------"
        echo "⚠️  ATTENTION : Le tuning Btrfs a été appliqué."
        echo "Pour que les Flatpaks soient compressés à l'installation,"
        echo "tu DOIS redémarrer ton système maintenant."
        echo "-------------------------------------------------------"
        echo "Relance ce script après le reboot pour finir l'étape [3/4]."
        exit 0 # On arrête le script proprement ici
    fi
fi



echo "--- [3/4] Import des préférences utilisateur (Stow) ---"
source ./modules/stow.sh

echo "--- [4/4] Installation des Flatpaks ---"
source ./modules/flatpak.sh

echo "✅ Déploiement terminé ! Redémarre le pc!"
