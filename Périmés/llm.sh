#!/usr/bin/env bash

DISK_LABEL="CARGO"  # Le nom de ton disque
RELATIVE_PATH="local_cache/LLM" # L'emplacement des LLM sur ce disque


# Trouver le point de montage de ce disque
# On cherche dans /dev/disk/by-label et on remonte au point de montage réel
DISK_MOUNT=$(lsblk -no MOUNTPOINT /dev/disk/by-label/$DISK_LABEL)

if [ -z "$DISK_MOUNT" ]; then
    notify-send "Erreur LLM" "Le disque '$DISK_LABEL' n'est pas branché ou monté."
    exit 1
fi

MODEL_DIR="$DISK_MOUNT/$RELATIVE_PATH"

# Contrôle de la présence du dossier des LLM
if [ ! -d "$MODEL_DIR" ]; then
    notify-send "Erreur LLM" "Dossier introuvable : $MODEL_DIR"
    exit 1
fi


# 1. Vérifier si llama-server tourne déjà
if pgrep -x "llama-server" > /dev/null; then
    notify-send "LLM" "Le serveur est déjà en cours d'exécution."
    xdg-open http://127.0.0.1:8080/
    exit
fi


# 2. Préparation de la liste des modèles (.gguf)
files=($MODEL_DIR/*.gguf)
options=()
for i in "${!files[@]}"; do
    options+=("$i" "$(basename "${files[$i]}")")
done

# 3. Sélection du modèle avec Dialog
CHOICE=$(dialog --backtitle "Gestionnaire LLM - Dell 5485" \
                --title " Sélection du Modèle " \
                --clear \
                --cancel-label "Annuler" \
                --menu "Choisis le modèle à charger :" 15 60 10 \
                "${options[@]}" \
                2>&1 >/dev/tty)

# Gestion de l'annulation
if [ $? -ne 0 ]; then clear; exit; fi

MODEL_PATH="${files[$CHOICE]}"
MODEL_NAME=$(basename "$MODEL_PATH")



echo $MODEL_PATH
echo $MODEL_NAME
echo $MODEL_DIR
echo "llama-server -m '$MODEL_PATH' -t 4 -c 4096 --no-mmap > /dev/null 2>&1"
llama-server -m $MODEL_PATH -t 4 -c 4096 --no-mmap
# llama-server -m '/var/mnt/1615eb5d-4346-4106-ba33-dbecf0b75b31/local_cache/LLM/gemma-3-4b-it-Q8_0.gguf' -t 4 -c 4096 --no-mmap > '/var/mnt/1615eb5d-4346-4106-ba33-dbecf0b75b31/local_cache/LLM/server.log' 2>&1

# 5. Ouverture du navigateur et stabilisation
#clear
echo "🚀 Le service llama-service est lancé."
echo "Appel de Firefox..."

# On utilise une redirection pour éviter de voir l'erreur EPERM de Firefox dans le terminal
xdg-open http://127.0.0.1:8080/ > /dev/null 2>&1

# On laisse 1 seconde de répit pour que la commande soit transmise au navigateur
sleep 1

echo "C'est prêt ! Ce terminal va se fermer."
sleep 1
exit
