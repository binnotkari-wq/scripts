#!/usr/bin/env bash

MODEL_DIR="/run/media/benoit/1615eb5d-4346-4106-ba33-dbecf0b75b31/local_cache/LLM"

# 1. Vérifier si llama-server tourne déjà
if pgrep -x "llama-server" > /dev/null; then
    # Ici on utilise une simple boîte de message dialog
    dialog --title "Erreur" --msgbox "Le serveur LLM est déjà en cours d'exécution." 6 40
    xdg-open http://127.0.0.1:8080/
    clear
    exit
fi

# 2. Ouvrir l'explorateur de fichiers ncurses
# --fselect permet de naviguer dans les dossiers et choisir un fichier
MODEL_PATH=$(dialog --stdout --title "Sélectionne ton modèle GGUF" \
    --fselect "$MODEL_DIR/" 10 60)

# Quitter si l'utilisateur a annulé (touche Échap ou bouton Annuler)
if [ $? -ne 0 ] || [ -z "$MODEL_PATH" ]; then
    clear
    exit
fi

# Vérifier si c'est bien un fichier et non un dossier
if [ -d "$MODEL_PATH" ]; then
    dialog --title "Erreur" --msgbox "Tu as sélectionné un dossier, pas un fichier !" 6 40
    clear
    exit
fi

# 3. Lancement du serveur
MODEL_NAME=$(basename "$MODEL_PATH")
clear
echo "Lancement de $MODEL_NAME sur le R5-3600..."

llama-server -m "$MODEL_PATH" -t 4 -c 4096 > "$MODEL_DIR/server.log" 2>&1 &

# 4. Notification finale
sleep 2
# On repasse sur notify-send pour que tu saches que c'est prêt même si le terminal est réduit
notify-send "LLM" "Serveur lancé avec : $MODEL_NAME"
xdg-open http://127.0.0.1:8080/
