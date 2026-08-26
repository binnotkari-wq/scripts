#!/usr/bin/env bash
# Mise à jour Homebrew (utilisateur uniquement, jamais en root).
set -euo pipefail


log() { logger -t system-update "$*"; echo "[system-update] $*"; }

log "Rafraîchissement des métadonnées firmware"
sudo fwupdmgr refresh --force || log "fwupdmgr refresh a échoué (pas bloquant)"
log "Vérification des mises à jour firmware disponibles"
sudo fwupdmgr get-updates || true   # code de retour != 0 si rien à mettre à jour
log "Application des mises à jour firmware"
sudo fwupdmgr update --assume-yes || log "fwupdmgr update : rien à appliquer ou échec"

if ! command -v bootc &>/dev/null; then
    echo "système non-bootc, rien à faire."
    exit 0
else
    log "Vérification d'une nouvelle image bootc"
    if sudo bootc upgrade --check; then
        log "Nouvelle image disponible, téléchargement en cours (staged, reboot requis)"
        sudo bootc upgrade
        log "Image stagée. Un redémarrage est nécessaire pour l'appliquer."
    else
        log "Déjà à jour, aucune image à télécharger"
    fi
fi

log "Mise à jour des flatpaks système"
flatpak update --system --assumeyes --noninteractive || log "flatpak update (system) a échoué"

log "Terminé"


log() { logger -t userland-update "$*"; echo "[userland-update] $*"; }

echo "Mise à jour des flatpaks utilisateur"
flatpak update --user --assumeyes --noninteractive || true

if ! command -v brew &>/dev/null; then
    echo "brew non installé, rien à faire."
    exit 0
else
    log "brew update"
    brew update

    log "brew outdated (aperçu)"
    brew outdated || true

    log "brew upgrade"
    brew upgrade

    log "brew autoremove"
    brew autoremove

    log "brew cleanup"
    brew cleanup --prune=all

    log "brew doctor (diagnostic, non bloquant)"
    brew doctor || true
fi

log "Terminé"
