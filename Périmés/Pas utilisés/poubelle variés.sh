#!/usr/bin/env bash

# Morceau de script inutile. Conservé juste pour références de commandes et syntaxe

# 4. Installation des logiels en Go :

# Liste
APPS_CLI_GO=(
    "github.com/zi0p4tch0/radiogogo@latest"
)

# Installation
echo "🎨 Installation des applications Go..."
go install "${APPS_CLI_GO[@]}"


# Déclaration du path de Go comme source de binaires
setup_bin_path() {
    BIN_DIR="$HOME/go"
    mkdir -p "$BIN_DIR"

    if ! grep -q "$BIN_DIR" ~/.bashrc; then
        echo -e "\n# Ajout du dossier bin personnel\nexport PATH=\"$BIN_DIR:\$PATH\"" >> ~/.bashrc
        echo "✅ Dossier bin ajouté au .bashrc"
    else
        echo "ℹ️  Le dossier bin est déjà dans le .bashrc"
    fi
    
    # Appliquer immédiatement pour la session actuelle du script
    export PATH="$BIN_DIR:$PATH"
}


echo "✅ Outils et logiciels CLI installés avec succès."

	
# =====================================
# Désinstaller Brew
# =====================================
#
# Supprimer le dossier de Brew :
# sudo rm -rf /home/linuxbrew
# Editer ~/.bashrc et enlever la ligne eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
# source ~/.bashrc # on recharge la configuration de l'environnement shell
