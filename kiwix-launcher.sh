#!/usr/bin/env bash

ZIM_DIR="/run/media/benoit/1615eb5d-4346-4106-ba33-dbecf0b75b31/local_cache/Kiwix zims"
PORT=8081

# On tue proprement l'instance précédente si elle existe
pkill kiwix-serve 2>/dev/null

# Lancement du serveur sur le dossier complet (plus pratique pour naviguer entre ZIMs)
kiwix-serve --port 8081 "$ZIM_DIR"/*.zim &

# Attente très courte (le binaire local est quasi instantané)
sleep 0.5

# Lancement de Firefox
# firefox "http://localhost:$PORT" &
xdg-open "http://localhost:$PORT" &
