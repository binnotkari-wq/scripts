#!/usr/bin/env bash

LABEL="cargo"  # Le nom de ton disque
RELATIVE_PATH="local_cache/LLM" # L'emplacement des LLM sur ce disque

##########################################################################################
# Méthode qui n'est plus utilisée.                                                       #
##########################################################################################
# Trouver le point de montage de ce disque
# On cherche dans /dev/disk/by-label et on remonte au point de montage réel
# DISK_MOUNT=$(lsblk -no MOUNTPOINT /dev/disk/by-label/$DISK_LABEL)

# if [ -z "$DISK_MOUNT" ]; then
#     notify-send "Erreur LLM" "Le disque '$DISK_LABEL' n'est pas branché ou monté."
#     exit 1
# fi

##########################################################################################
# Desormais on part du principe que le volume (disque ou partition) est monté sur /cargo #
##########################################################################################
MODEL_DIR="/$LABEL/$RELATIVE_PATH"

# Contrôle de la présence du dossier des LLM
if [ ! -d "$MODEL_DIR" ]; then
    notify-send "Erreur LLM" "Dossier introuvable : $MODEL_DIR"
    exit 1
fi


# 1. Vérifier si le service tourne déjà
if systemctl --user is-active --quiet llama-service; then
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
CHOICE=$(dialog --backtitle "Gestionnaire LLM" \
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

# 4. Lancement via un service éphémère systemd
# On redirige la sortie vers ton log habituel pour garder une trace
systemd-run --user --unit=llama-service --description="Serveur Llama CPP" \
    bash -c "llama-server -m $MODEL_PATH -t 4 -c 4096 --no-mmap #> $MODEL_DIR/server.log 2>&1"


# 5. Ouverture du navigateur et stabilisation
#clear
echo "🚀 Le service llama-service est lancé."
echo "Appel de Firefox..."

# On utilise une redirection pour éviter de voir l'erreur EPERM de Firefox dans le terminal
xdg-open http://127.0.0.1:8080/ > /dev/null 2>&1

# On laisse 1 seconde de répit pour que la commande soit transmise au navigateur
sleep 1

echo "C'est prêt ! Ce terminal va se fermer."
sleep 10
# exit
