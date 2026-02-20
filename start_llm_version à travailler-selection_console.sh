#!/usr/bin/env bash

MODEL_DIR="/run/media/benoit/1615eb5d-4346-4106-ba33-dbecf0b75b31/local_cache/LLM"
CTX=4096

# 1. Vérifier si llama-server tourne déjà
if pgrep -x "llama-server" > /dev/null; then
    echo "LLM" "Le serveur est déjà en cours d'exécution."
    xdg-open http://127.0.0.1:8080/
    exit
fi


# 1. Lister les modèles disponibles
echo "--- Modèles disponibles ---"
models=($MODEL_DIR/*.gguf)
for i in "${!models[@]}"; do
    echo "$i) $(basename "${models[$i]}")"
done

# 2. Demander le choix
read -p "Choisir le numéro du modèle à lancer : " choice

SELECTED_MODEL="${models[$choice]}"



# 4. Lancement du serveur
llama-server -m "$SELECTED_MODEL" -t 4 -c $CTX > "$MODEL_DIR/server.log" 2>&1 &

# 5. Notification et ouverture
sleep 2
echo "LLM" "Serveur lancé avec : $basename"
xdg-open http://127.0.0.1:8080/
exit
