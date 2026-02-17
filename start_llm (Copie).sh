#!/usr/bin/env bash

# 1. Vérifier si llama-server tourne déjà
if pgrep -x "llama-server" > /dev/null
then
    echo "LLM" "Le serveur est déjà en cours d'exécution."
    xdg-open http://127.0.0.1:8080/
    exit
fi

# 2. Demander à l'utilisateur quel modèle utiliser (Menu KDE)
CHOIX=$(kdialog --menu "Quel modèle souhaites-tu réveiller ?" \
    "G" "Gemma 3 1B (Rapide)" \
    "L" "Llama 3.2 3B (Intelligent)" \
    "Q" "Qwen 2.5 Coder 3B (Intelligent)")

# Vérifier si l'utilisateur a annulé
if [ $? -ne 0 ]; then
    exit
fi

# 3. Configurer les variables selon le choix
if [ "$CHOIX" == "G" ]; then
    MODEL_PATH="$HOME/LLM/gemma-3-1b-it-Q4_K_M.gguf"
    MODEL_NAME="Gemma 3 1B"
elif [ "$CHOIX" == "L" ]; then
    MODEL_PATH="$HOME/LLM/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    MODEL_NAME="Llama 3.2 3B"
else
    MODEL_PATH="$HOME/LLM/Qwen2.5-Coder-3B-Instruct-abliterated-Q4_K_M.gguf"
    MODEL_NAME="Qwen 2.5 Coder 3B"
fi

# 4. Lancement du serveur
llama-server -m "$MODEL_PATH" -t 4 -c 4096 > "$HOME/LLM/server.log" 2>&1 &

# 5. Attente et ouverture
sleep 2
xdg-open http://127.0.0.1:8080/

echo "LLM" "Serveur lancé avec succès ($MODEL_NAME)"
