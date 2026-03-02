#!/usr/bin/env bash

MODEL_DIR="/run/media/benoit/1615eb5d-4346-4106-ba33-dbecf0b75b31/local_cache/LLM"

# 1. Vérifier si llama-server tourne déjà
if pgrep -x "llama-server" > /dev/null; then
    notify-send "LLM" "Le serveur est déjà en cours d'exécution."
    xdg-open http://127.0.0.1:8080/
    exit
fi

# 2. Préparation de la liste pour 'dialog'
# On récupère tous les fichiers .gguf et on crée une liste formatée pour dialog
files=($MODEL_DIR/*.gguf)
options=()
for i in "${!files[@]}"; do
    options+=("$i" "$(basename "${files[$i]}")")
done

# 3. Affichage de l'interface de sélection
# On utilise une redirection de descripteur (3>&1 1>&2 2>&3) pour capturer le choix
CHOICE=$(dialog --backtitle "Gestionnaire LLM - Dell 5485" \
                --title " Sélection du Modèle " \
                --clear \
                --cancel-label "Annuler" \
                --menu "Choisis le modèle à charger en RAM :" 15 60 10 \
                "${options[@]}" \
                2>&1 >/dev/tty)

# 4. Gestion de l'annulation (Bouton Annuler ou touche Echap)
exit_status=$?
if [ $exit_status -ne 0 ] || [ -z "$CHOICE" ]; then
    clear
    echo "Opération annulée."
    sleep 1
    exit
fi

# 5. Récupération du chemin complet
MODEL_PATH="${files[$CHOICE]}"
MODEL_NAME=$(basename "$MODEL_PATH")

# 6. Lancement du serveur (en arrière-plan)
llama-server -m "$MODEL_PATH" -t 4 -c 4096 > "$MODEL_DIR/server.log" 2>&1 &


# 7. Ouverture du navigateur et stabilisation
clear
echo "🚀 Le service llama-service est lancé."
echo "Appel de Firefox..."

# On utilise une redirection pour éviter de voir l'erreur EPERM de Firefox dans le terminal
xdg-open http://127.0.0.1:8080/ > /dev/null 2>&1

# On laisse 1 seconde de répit pour que la commande soit transmise au navigateur
sleep 1

echo "C'est prêt ! Ce terminal va se fermer."
sleep 1
exit
