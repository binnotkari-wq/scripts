#!/usr/bin/env bash

ZIM_DIR="/home/benoit/Mes-Donnees/03_Ressources_Externes/Kiwix zims"
PORT=8080

# On tue proprement l'instance précédente si elle existe
pkill kiwix-serve 2>/dev/null

# Lancement du serveur sur le dossier complet (plus pratique pour naviguer entre ZIMs)
kiwix-serve --port 8080 "$ZIM_DIR"/*.zim &

# Attente très courte (le binaire local est quasi instantané)
sleep 0.5

# Lancement de Firefox
firefox "http://localhost:$PORT" &
