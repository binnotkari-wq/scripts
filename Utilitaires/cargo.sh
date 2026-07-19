#!/usr/bin/env bash

##################################################################################################
# cargo.sh — provisiont d'un dataset essentiel sur le sous-volume, ou disque, monté sur /cargo   #
# Usage : ./cargo.sh                                                                             #
##################################################################################################

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
#  PROVISIONNEMENT DE cargo (sous-volume ou disque monté sur /cargo
#  Téléchargement des modèles LLM et des fichiers Kiwix (.zim) essentiels.
# ═══════════════════════════════════════════════════════════════════════════
provisionner_cargo() {

    echo ""
    echo "════════════════════════════════════════════════"
    echo "  Provisionnement du dataset essentiel sur cargo"
    echo "════════════════════════════════════════════════"
    read -rp "Prêt à télécharger LLM et .zim ? (oui) : " CONFIRM
    [[ "$CONFIRM" == "oui" ]] || { echo "Annulé."; return 0; }

    # Récupérer le propriétaire actuel de /cargo
    current_owner_uid=$(stat -c '%u' /cargo)
    # Récupérer l'utilisateur actuel
    current_user_uid=$(id -u)

    # Si le propriétaire n'est pas l'utilisateur actuel, on corrige
    if [ "$current_owner_uid" != "$current_user_uid" ]; then
        echo "Le propriétaire de /cargo n'est pas $(whoami). Correction..."
        sudo chown -R "$(id -u):$(id -g)" /cargo
    fi

    # ─── 1. Téléchargement des LLM ────────────────────────────────────────
    echo "Installation de aria2..."
    nix-env -iA nixos.aria2

    LLM_DIR="/cargo/local_cache/LLM"
    mkdir -p "$LLM_DIR"

    echo ""
    echo "Vérification des modèles LLM..."

    PHI4="$LLM_DIR/Phi-4-mini-instruct-Q4_K_M.gguf"
    LLAMA="$LLM_DIR/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf"

    if [[ ! -f "$PHI4" ]]; then
        echo "Téléchargement de Phi-4-mini..."
        aria2c --dir="$LLM_DIR" \
               --out="Phi-4-mini-instruct-Q4_K_M.gguf" \
               --continue=true \
               --max-connection-per-server=4 \
               "https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf"
    else
        echo "✓ Phi-4-mini déjà présent, téléchargement ignoré."
    fi

    if [[ ! -f "$LLAMA" ]]; then
        echo "Téléchargement de Llama-3.1-8B..."
        aria2c --dir="$LLM_DIR" \
               --out="Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf" \
               --continue=true \
               --max-connection-per-server=4 \
               "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf"
    else
        echo "✓ Llama-3.1-8B déjà présent, téléchargement ignoré."
    fi

    # ─── 2. Téléchargement des fichiers ZIM ───────────────────────────────
    ZIM_DIR="/cargo/local_cache/Kiwix zims"
    mkdir -p "$ZIM_DIR"

    echo ""
    echo "Vérification des fichiers Kiwix..."

    WIKI_FR="$ZIM_DIR/wikipedia_fr_all_mini_2026-02.zim"
    IFIXIT="$ZIM_DIR/ifixit_en_all_2025-12.zim"

    if [[ ! -f "$WIKI_FR" ]]; then
        echo "Téléchargement de Wikipedia FR..."
        aria2c --dir="$ZIM_DIR" \
               --continue=true \
               --max-connection-per-server=4 \
               "https://download.kiwix.org/zim/wikipedia/wikipedia_fr_all_mini_2026-02.zim"
    else
        echo "✓ Wikipedia FR déjà présent, téléchargement ignoré."
    fi

    if [[ ! -f "$IFIXIT" ]]; then
        echo "Téléchargement de iFixit..."
        aria2c --dir="$ZIM_DIR" \
               --continue=true \
               --max-connection-per-server=4 \
               "https://download.kiwix.org/zim/ifixit/ifixit_en_all_2025-12.zim"
    else
        echo "✓ iFixit déjà présent, téléchargement ignoré."
    fi
}
