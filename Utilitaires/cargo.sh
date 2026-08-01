#!/usr/bin/env bash

##################################################################################################
# cargo.sh — provisiont d'un dataset essentiel sur le sous-volume, ou disque, monté sur /cargo   #
# Usage : ./cargo.sh                                                                             #
##################################################################################################

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
#  CREATION DU SOUS-VOLUME BTRFS CARGO (SPECIFIQUE DEPLOIEMENT PAR REBUILD)
#  s'il n'exite pas encore physiquement sur le disque.
#  Devra être déclare dans les .nix pour être monté au prochain démarrage.
# ═══════════════════════════════════════════════════════════════════════════
creer_cargo() {
    OPTS="noatime,compress=zstd,space_cache=v2,ssd,discard=async"
    ROOT_FSTYPE=$(findmnt -no FSTYPE /nix)  # on regarde quel est le système de fichier principal (celui sur lequel est /nix dans le cas d'un volume btrfs)
    ROOT_DEVICE=$(findmnt -no SOURCE /nix | sed 's/\[.*//') # on extrait le device
    TMP_MOUNT=$(mktemp -d)

    if [[ "$ROOT_FSTYPE" != "btrfs" ]]; then
        echo "⚠ Le système de fichiers racine n'est pas btrfs ($ROOT_FSTYPE détecté). Abandon."
    else
        # On monte le volume btrfs à son niveau racine absolu (subvolid=5), seul
        # niveau depuis lequel on peut créer un sous-volume au même rang que
        # $ROOT_SUBVOLUME, home, nix, persist, etc.
        mount -o subvolid=5 "$ROOT_DEVICE" "$TMP_MOUNT"

        CARGO_EXISTS=$(btrfs subvolume list "$TMP_MOUNT" | awk '{print $NF}' | grep -xF "cargo" || true)
        if [[ -n "$CARGO_EXISTS" ]]; then
            echo "✓ Le sous-volume 'cargo' existe déjà, aucune action nécessaire."
        else
            btrfs subvolume create "$TMP_MOUNT/cargo"
            echo "✓ Sous-volume 'cargo' créé."
        fi
        umount "$TMP_MOUNT"
        rmdir "$TMP_MOUNT" 2>/dev/null || true
    mount -o "$OPTS,subvol=cargo"  "$ROOT_DEVICE" /cargo
    fi
}

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

creer_cargo
provisionner_cargo
