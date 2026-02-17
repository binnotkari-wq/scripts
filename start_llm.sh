#!/usr/bin/env bash

MODEL_DIR="/run/media/benoit/1615eb5d-4346-4106-ba33-dbecf0b75b31/local_cache/LLM"

# 1. Vérifier si llama-server tourne déjà
if pgrep -x "llama-server" > /dev/null; then
    notify-send "LLM" "Le serveur est déjà en cours d'exécution."
    xdg-open http://127.0.0.1:8080/
    exit
fi

# 2. Fonction de sélection de fichier intelligente
choisir_fichier() {
    # Détection de l'environnement
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        # Version KDE (KDialog)
        kdialog --getopenfilename "$MODEL_DIR" "*.gguf|Modèles GGUF" --title "Choisir un modèle"
    elif [ -x "$(command -v zenity)" ]; then
        # Version GNOME/Universelle (Zenity)
        zenity --file-selection --filename="$MODEL_DIR/" --file-filter="*.gguf" --title="Choisir un modèle"
    else
        # Fallback si rien n'est trouvé (simple lecture de texte)
        echo "Aucun outil GUI trouvé. Tape le chemin du modèle :" >&2
        read -r chemin
        echo "$chemin"
    fi
}

# 3. Appel de la fonction
MODEL_PATH=$(choisir_fichier)

# Quitter si l'utilisateur a annulé
if [ -z "$MODEL_PATH" ] || [ "$MODEL_PATH" = " " ]; then
    exit
fi

# 4. Lancement du serveur
MODEL_NAME=$(basename "$MODEL_PATH")
llama-server -m "$MODEL_PATH" -t 4 -c 4096 > "$MODEL_DIR/server.log" 2>&1 &

# 5. Notification et ouverture
sleep 2
notify-send "LLM" "Serveur lancé avec : $MODEL_NAME"
xdg-open http://127.0.0.1:8080/
