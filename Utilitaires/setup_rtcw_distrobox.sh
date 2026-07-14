#!/usr/bin/env bash
# ==============================================================================
# Script d'initialisation de la Distrobox "gaming" et du raccourci RTCW
# Portable et indépendant de NixOS / Home Manager
# ==============================================================================

set -euo pipefail

# Configuration des chemins
DISTROBOX_CONFIG_DIR="${HOME}/.config/distrobox"
ASSEMBLE_INI="${DISTROBOX_CONFIG_DIR}/assemble.ini"
DESKTOP_DIR="${HOME}/.local/share/applications"
DESKTOP_FILE="${DESKTOP_DIR}/rtcw.desktop"

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==>${NC} Début de la configuration de l'environnement de jeu..."

# 1. Vérification des prérequis (distrobox et podman/docker)
if ! command -v distrobox &> /dev/null; then
    echo -e "${YELLOW}[!] Attention : 'distrobox' n'est pas installé ou n'est pas dans votre PATH.${NC}"
    echo "Veuillez l'installer via le gestionnaire de paquets de votre distribution."
fi

# 2. Création du répertoire de configuration s'il n'existe pas
mkdir -p "${DISTROBOX_CONFIG_DIR}"

# 3. Génération du fichier assemble.ini
echo -e "${BLUE}==>${NC} Création du fichier d'assemblage : ${ASSEMBLE_INI}"
cat << 'EOF' > "${ASSEMBLE_INI}"
[gaming]
image=ubuntu:24.04
volume=/cargo:/cargo
init_hooks=dpkg --add-architecture i386 && apt update && apt install -y libsdl2-2.0-0 libsdl2-2.0-0:i386 libsdl1.2debian:i386 libgl1:i386 libopenal1:i386
EOF

# 4. Exécution de distrobox assemble
if command -v distrobox &> /dev/null; then
    echo -e "${BLUE}==>${NC} Lancement de la création/mise à jour du conteneur Distrobox..."
    distrobox assemble create --file "${ASSEMBLE_INI}"
else
    echo -e "${YELLOW}[!] Étape d'assemblage ignorée car 'distrobox' est manquant.${NC}"
fi

# 5. Création du dossier d'applications utilisateur si manquant
mkdir -p "${DESKTOP_DIR}"

# 6. Génération du fichier .desktop de raccourci pour RTCW
echo -e "${BLUE}==>${NC} Génération du raccourci de bureau : ${DESKTOP_FILE}"
cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Name=Return to Castle Wolfenstein
Comment=Lancer Return to Castle Wolfenstein
Exec=distrobox-enter --name gaming -- "/cargo/Jeux natifs/iortcw-1.51c-linux-x86_64/iowolfsp.x86_64"
Icon=/cargo/Jeux natifs/iortcw-1.51c-linux-x86_64/WolfSP.xpm
Terminal=false
Type=Application
Categories=Game;
EOF

# Rendre le raccourci exécutable (requis par certains environnements)
chmod +x "${DESKTOP_FILE}"

echo -e "${GREEN}==> Configuration terminée avec succès !${NC}"
echo -e "${GREEN}==>${NC} Le raccourci est disponible dans votre menu d'applications sous le nom : ${YELLOW}Return to Castle Wolfenstein${NC}"
