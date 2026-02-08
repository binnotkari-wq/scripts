#!/usr/bin/env bash

# On cherche et on tue le processus
if pkill llama-server
then
    echo "LLM" "Le serveur a été arrêté."
else
    echo "LLM" "Aucun serveur n'était en cours d'exécution."
fi
