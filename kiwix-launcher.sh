#!/usr/bin/env bash

DISK_LABEL="cargo"  # Le nom de ton disque
RELATIVE_PATH="local_cache/Kiwix zims" # L'emplacement des LLM sur ce disque
PORT=8081

# Trouver le point de montage de ce disque
# On cherche dans /dev/disk/by-label et on remonte au point de montage réel
DISK_MOUNT=$(lsblk -no MOUNTPOINT /dev/disk/by-label/$DISK_LABEL)

if [ -z "$DISK_MOUNT" ]; then
    notify-send "Erreur LLM" "Le disque '$DISK_LABEL' n'est pas branché ou monté."
    exit 1
fi

ZIM_DIR="$DISK_MOUNT/$RELATIVE_PATH"

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
