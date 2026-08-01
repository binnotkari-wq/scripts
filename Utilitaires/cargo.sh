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
#!/usr/bin/env bash
# setup_cargo.sh
#
# Sonde l'existence d'un volume "cargo" (sous-volume btrfs ou disque étiqueté),
# le crée si besoin, génère modules/cargo.nix en conséquence, l'ajoute aux
# imports du host courant, puis rebuild switch.
#
# Prérequis : exécuté en root, sur un NixOS installé et en cours d'utilisation.
# Le fichier cargo.nix généré est propre à la machine (voir .gitignore du dépôt).

set -euo pipefail

# --- Paramètres ------------------------------------------------------------

NIXOS_USER="${SUDO_USER:-$USER}"
HOSTNAME_SHORT=$(hostname -s)
DOTFILES_DIR="/home/${NIXOS_USER}/Git/nixos-dotfiles"
MODULES_DIR="${DOTFILES_DIR}/modules"
HOST_FILE="${DOTFILES_DIR}/hosts/${HOSTNAME_SHORT}.nix"
CARGO_NIX="${MODULES_DIR}/cargo.nix"

if [[ $EUID -ne 0 ]]; then
    echo "⚠ Ce script doit être exécuté en root (sudo)." >&2
    exit 1
fi

if [[ ! -f "$HOST_FILE" ]]; then
    echo "⚠ Fichier host introuvable : $HOST_FILE" >&2
    echo "  (vérifie que le hostname (${HOSTNAME_SHORT}) correspond bien à un fichier dans hosts/)" >&2
    exit 1
fi

if [[ ! -d "$MODULES_DIR" ]]; then
    echo "⚠ Dossier modules introuvable : $MODULES_DIR" >&2
    exit 1
fi

# --- Étape 1 : disque étiqueté "cargo" ? -----------------------------------

echo "== Étape 1 : recherche d'un disque étiqueté 'cargo' =="
CARGO_DISK=$(blkid -L cargo 2>/dev/null || true)

CARGO_MODE=""       # "disk" ou "subvolume"
CARGO_DEVICE=""      # utilisé uniquement en mode "subvolume"

if [[ -n "$CARGO_DISK" ]]; then
    echo "✓ Disque 'cargo' trouvé : $CARGO_DISK"
    CARGO_MODE="disk"
else
    echo "  Aucun disque étiqueté 'cargo'."

    # --- Étape 2 : sous-volume btrfs "cargo" ? -----------------------------

    echo "== Étape 2 : recherche d'un sous-volume btrfs 'cargo' =="

    # On regarde quel est le système de fichier principal (celui sur lequel
    # est /nix), car / peut être un tmpfs en impermanence.
    ROOT_FSTYPE=$(findmnt -no FSTYPE /nix)
    ROOT_DEVICE=$(findmnt -no SOURCE /nix | sed 's/\[.*//')

    if [[ "$ROOT_FSTYPE" != "btrfs" ]]; then
        echo "⚠ Le système de fichiers racine n'est pas btrfs (${ROOT_FSTYPE} détecté). Abandon."
        exit 1
    fi

    TMP_MOUNT=$(mktemp -d)

    # On monte le volume btrfs à son niveau racine absolu (subvolid=5), seul
    # niveau depuis lequel on peut créer un sous-volume au même rang que
    # $ROOT_SUBVOLUME, home, nix, persist, etc.
    mount -o subvolid=5 "$ROOT_DEVICE" "$TMP_MOUNT"

    CARGO_EXISTS=$(btrfs subvolume list "$TMP_MOUNT" | awk '{print $NF}' | grep -xF "cargo" || true)

    if [[ -n "$CARGO_EXISTS" ]]; then
        echo "✓ Le sous-volume 'cargo' existe déjà."
    else
        btrfs subvolume create "$TMP_MOUNT/cargo"
        echo "✓ Sous-volume 'cargo' créé (top level 5)."
    fi

    umount "$TMP_MOUNT"
    rmdir "$TMP_MOUNT" 2>/dev/null || true

    CARGO_MODE="subvolume"
    CARGO_DEVICE="$ROOT_DEVICE"
fi

# --- Étape 3 : génération de modules/cargo.nix ------------------------------

echo "== Étape 3 : génération de ${CARGO_NIX} =="

if [[ "$CARGO_MODE" == "disk" ]]; then
    cat > "$CARGO_NIX" <<'EOF'
# Fichier généré automatiquement par setup_cargo.sh — propre à cette machine,
# ne pas versionner (voir .gitignore du dépôt).
{ config, pkgs, ... }:
{
  fileSystems."/cargo" =
    { device = "/dev/disk/by-label/cargo";
      fsType = "btrfs";
      # nofail = le système boote même si le disque est absent
      options = [ "nofail" "noatime" "compress=zstd" "ssd" "discard=async" ];
    };
}
EOF
else
    cat > "$CARGO_NIX" <<EOF
# Fichier généré automatiquement par setup_cargo.sh — propre à cette machine,
# ne pas versionner (voir .gitignore du dépôt).
# Device codé en dur (plutôt que via vars.luksUuid) pour ne pas dépendre de
# variables.nix dans un fichier qui n'existe que localement.
{ config, pkgs, ... }:
{
  fileSystems."/cargo" =
    { device = "${CARGO_DEVICE}";
      fsType = "btrfs";
      options = [ "subvol=cargo" "noatime" "compress=zstd" "ssd" "discard=async" ];
    };
}
EOF
fi

echo "✓ ${CARGO_NIX} généré (mode : ${CARGO_MODE})."

# --- Étape 4 : ajout de l'import dans le host --------------------------------

echo "== Étape 4 : ajout de l'import dans ${HOST_FILE} =="

if grep -q '\.\./modules/cargo\.nix' "$HOST_FILE"; then
    echo "  Import déjà présent, rien à faire."
else
    # On repère la ligne "imports = ..." puis on insère juste après le
    # premier "[" rencontré à partir de là (que ce soit sur la même ligne
    # ou une ligne suivante).
    awk '
        { print }
        /imports[[:space:]]*=/ { in_imports=1 }
        in_imports && /\[/ && !inserted {
            print "      ../modules/cargo.nix"
            inserted=1
        }
    ' "$HOST_FILE" > "${HOST_FILE}.tmp"

    if ! grep -q '\.\./modules/cargo\.nix' "${HOST_FILE}.tmp"; then
        echo "⚠ Impossible de localiser le bloc 'imports = [ ... ]' dans ${HOST_FILE}." >&2
        echo "  Ajoute ../modules/cargo.nix manuellement, puis relance le rebuild." >&2
        rm -f "${HOST_FILE}.tmp"
    else
        mv "${HOST_FILE}.tmp" "$HOST_FILE"
        echo "✓ Import ajouté en tête de liste."
    fi
fi

# --- Étape 5 : rebuild switch ------------------------------------------------

echo "== Étape 5 : nixos-rebuild switch =="
nixos-rebuild switch

echo
echo "✓ Terminé."
findmnt /cargo || echo "⚠ /cargo n'apparaît pas monté, vérifie la config."
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
