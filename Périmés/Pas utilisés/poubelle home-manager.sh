#!/usr/bin/env bash

echo "❄️  Initialisation de Home Manager (Version Stable 25.11)..."

# 1. Configuration des canaux (Stable)
echo "📦 Configuration des sources Nix..."
nix-channel --add https://nixos.org/channels/nixos-25.11 nixpkgs
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
nix-channel --update

# 2. Installation de Home Manager si absent
if ! command -v home-manager &> /dev/null; then
    echo "📥 Installation initiale de Home Manager..."
    nix-shell '<home-manager>' -A install
fi

# 3. Déploiement via chemin absolu
HM_CONFIG_FILE="$MY_GIT_DIR/home-manager/home.nix"

if [ -f "$HM_CONFIG_FILE" ]; then
    echo "⚙️  Application de la configuration : $HM_CONFIG_FILE"
    
    # Utilisation du chemin direct vers le fichier
    home-manager switch -f "$HM_CONFIG_FILE"
else
    echo "⚠️  Erreur : $HM_CONFIG_FILE introuvable."
    echo "Assure-toi que git-clone.sh a bien récupéré tes dépôts."
fi
