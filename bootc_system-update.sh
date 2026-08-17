#!/usr/bin/env bash
# Mise à jour système : firmware, image bootc, flatpaks système.
set -euo pipefail

log() { logger -t system-update "$*"; echo "[system-update] $*"; }

log "Rafraîchissement des métadonnées firmware"
fwupdmgr refresh --force || log "fwupdmgr refresh a échoué (pas bloquant)"

log "Vérification des mises à jour firmware disponibles"
fwupdmgr get-updates || true   # code de retour != 0 si rien à mettre à jour

log "Application des mises à jour firmware"
fwupdmgr update --assume-yes || log "fwupdmgr update : rien à appliquer ou échec"

log "Mise à jour des flatpaks système"
flatpak update --system --assumeyes --noninteractive || log "flatpak update (system) a échoué"

log "Vérification d'une nouvelle image bootc"
if bootc upgrade --check; then
    log "Nouvelle image disponible, téléchargement en cours (staged, reboot requis)"
    bootc upgrade
    log "Image stagée. Un redémarrage est nécessaire pour l'appliquer."
else
    log "Déjà à jour, aucune image à télécharger"
fi

log "Terminé"
