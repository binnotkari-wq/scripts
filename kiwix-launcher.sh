#!/usr/bin/env bash

LABEL="cargo"  # Le nom du volume de stockage des LLM (nom du disque ou de la partition)
RELATIVE_PATH="local_cache/Kiwix zims" # L'emplacement des LLM sur ce volume
PORT=8081

##########################################################################################
# Méthode qui n'est plus utilisée.                                                       #
##########################################################################################
# On cherche dans /dev/disk/by-label et on remonte au point de montage réel
# DISK_MOUNT=$(lsblk -no MOUNTPOINT /dev/disk/by-label/$LABEL)

# if [ -z "$DISK_MOUNT" ]; then
#    notify-send "Le disque '$DISK_LABEL' n'est pas branché ou monté."
#    exit 1
# fi

##########################################################################################
# Desormais on part du principe que le volume (disque ou partition) est monté sur /cargo #
##########################################################################################
ZIM_DIR="/$LABEL/$RELATIVE_PATH"

# Contrôle de la présence du dossier des LLM
if [ ! -d "$ZIM_DIR" ]; then
    notify-send "Erreur Zim" "Dossier introuvable : $ZIM_DIR"
    exit 1
fi

# On tue proprement l'instance précédente si elle existe
pkill kiwix-serve 2>/dev/null

# Lancement du serveur sur le dossier complet (plus pratique pour naviguer entre ZIMs)
kiwix-serve --port 8081 "$ZIM_DIR"/*.zim &

# Attente très courte (le binaire local est quasi instantané)
sleep 2

# Lancement de Firefox
xdg-open "http://localhost:$PORT" &
