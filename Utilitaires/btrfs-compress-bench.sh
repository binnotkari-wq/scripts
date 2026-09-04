#!/usr/bin/env bash
#
# btrfs-compress-bench.sh
#
# Compare compress=zstd:1 / compress=zstd:3 / compress-force=zstd:1 / compress-force=zstd:3
# sur un dataset synthétique mais réaliste (mix compressible / incompressible),
# provisionné automatiquement. A exécuter EN ROOT dans une VM jetable.
#
# Nécessite : btrfs-progs, compsize (paquet btrfs-compsize / compsize selon distro)
#
# Usage : sudo ./btrfs-compress-bench.sh [taille_image_Go]
#
set -euo pipefail

IMG_SIZE_GB="${1:-8}"
# IMPORTANT : /tmp est souvent un tmpfs (RAM) sous Fedora/systemd. Une image btrfs de
# plusieurs Go dedans consomme de la RAM et peut heurter la limite tmpfs, ce qui remonte
# comme une erreur I/O (-5) côté btrfs et force un remontage en lecture seule.
# /var/tmp est presque toujours sur disque réel : on l'utilise pour l'image de test.
WORKDIR="$(mktemp -d /var/tmp/btrfs-bench.XXXXXX)"
IMG="${WORKDIR}/test.img"
MNT="${WORKDIR}/mnt"
DATASET="${WORKDIR}/dataset"
RESULTS="${WORKDIR}/results.txt"

trap 'echo "ERREUR ligne $LINENO : commande \"$BASH_COMMAND\" a échoué (code $?)" >&2' ERR
trap 'cleanup' EXIT

cleanup() {
    set +e
    if mountpoint -q "$MNT" 2>/dev/null; then
        umount "$MNT" 2>/dev/null
    fi
    rm -rf "$WORKDIR"
}

require() {
    command -v "$1" >/dev/null 2>&1 || { echo "Manque la commande : $1 (essaie: apt/dnf/pacman install $2)"; exit 1; }
}

echo "== Vérification des dépendances =="
require mkfs.btrfs btrfs-progs
require compsize compsize
require zstd zstd

if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être lancé en root (montage de loop device btrfs)." >&2
    exit 1
fi

mkdir -p "$MNT" "$DATASET"

# Vérifie que le point de montage du workdir n'est pas un tmpfs (RAM), ce qui causerait
# le même problème d'ENOSPC/EIO qu'avec /tmp.
FS_TYPE=$(df --output=fstype "$WORKDIR" | tail -n1)
if [[ "$FS_TYPE" == "tmpfs" ]]; then
    echo "ATTENTION : $WORKDIR est sur tmpfs (RAM) — risque d'erreur I/O si l'image dépasse la RAM libre." >&2
    echo "Système de fichiers détecté : $FS_TYPE" >&2
    df -h "$WORKDIR" >&2
fi

echo "== Provisionnement du dataset synthétique dans $DATASET =="

echo "-- Copie de fichiers texte réels --"
# 1) Données très compressibles : sources/textes/logs (on duplique des fichiers texte du système)
mkdir -p "$DATASET/text"
find /usr/share/doc -name "*.txt" -o -name "*.md" 2>/dev/null | head -n 500 \
    | xargs -I{} cp --parents {} "$DATASET/text" 2>/dev/null || true

echo "-- Génération de logs synthétiques --"
# Complète avec du texte généré si le système n'en fournit pas assez
# NB: 'yes | head' casse la pipe (SIGPIPE sur yes, code 141) ce qui, avec set -o pipefail,
# ferait échouer silencieusement tout le script. On neutralise ce code de sortie attendu.
for i in $(seq 1 50); do
    { yes "Ceci est une ligne de log répétitive pour simuler des fichiers texte compressibles. Ligne $i." \
        | head -n 2000 > "$DATASET/text/synth_log_$i.log"; } || true
done

echo "-- Copie de binaires réels (/usr/bin, /usr/lib) --"
# 2) Données moyennement compressibles : binaires ELF réels du système (proche d'un rootfs)
mkdir -p "$DATASET/bin"
find /usr/bin /usr/lib -type f 2>/dev/null | shuf -n 300 2>/dev/null \
    | xargs -I{} cp {} "$DATASET/bin/" 2>/dev/null || true

# 3) Données incompressibles : pseudo-aléatoire rapide (simule vidéos/archives/images déjà compressées)
#    /dev/urandom est trop lent en VM (pool CSPRNG, souvent pas de virtio-rng) : on utilise
#    openssl (RC4/AES-CTR en mode PRNG) qui débite en centaines de Mo/s au lieu de quelques Mo/s.
echo "-- Génération des blobs pseudo-aléatoires (rapide, via openssl) --"
mkdir -p "$DATASET/random"
for i in $(seq 1 5); do
    # Entrée bornée (dd count=) plutôt que 'head -c' sur flux infini : évite un SIGPIPE
    # qui, avec 'set -o pipefail', ferait planter le script silencieusement.
    dd if=/dev/zero bs=1M count=100 2>/dev/null \
        | openssl enc -aes-256-ctr -pass pass:"seed_$i" -nosalt 2>/dev/null \
        > "$DATASET/random/blob_$i.bin"
done

# 4) Cas piège : "gros fichier" façon image VM, compressible seulement sur une portion
#    (zeros en tête, données pseudo-aléatoires ensuite -> teste l'heuristique compress= vs compress-force=)
echo "-- Génération du fichier vmlike.img --"
dd if=/dev/zero of="$DATASET/vmlike.img" bs=1M count=200 status=none
dd if=/dev/zero bs=1M count=200 2>/dev/null \
    | openssl enc -aes-256-ctr -pass pass:"vmlike_seed" -nosalt 2>/dev/null \
    | dd of="$DATASET/vmlike.img" bs=1M seek=200 status=none conv=notrunc

DATASET_SIZE=$(du -sb "$DATASET" | cut -f1)
echo "Dataset total : $(numfmt --to=iec "$DATASET_SIZE")"
echo ""

# Garde-fou : btrfs a besoin d'une marge confortable au-delà de la taille brute des données
# (réserves de métadonnées, cas "compress=" qui ne compresse pas tout). En dessous de
# dataset x3, le risque de remontage en lecture seule (ENOSPC métadonnées) est réel.
IMG_SIZE_BYTES=$((IMG_SIZE_GB * 1024 * 1024 * 1024))
MIN_RECOMMENDED=$((DATASET_SIZE * 3))
if (( IMG_SIZE_BYTES < MIN_RECOMMENDED )); then
    RECOMMENDED_GB=$(( (MIN_RECOMMENDED / 1024 / 1024 / 1024) + 1 ))
    echo "ATTENTION : image de ${IMG_SIZE_GB}G trop petite pour un dataset de $(numfmt --to=iec "$DATASET_SIZE")." >&2
    echo "btrfs risque de se remonter en lecture seule (ENOSPC métadonnées) en cours de test." >&2
    echo "Relance avec au moins : sudo $0 ${RECOMMENDED_GB}" >&2
    exit 1
fi

# Création de l'image btrfs
echo "== Création de l'image btrfs (${IMG_SIZE_GB}G) =="
truncate -s "${IMG_SIZE_GB}G" "$IMG"
mkfs.btrfs -f -q "$IMG" >/dev/null

run_case() {
    local label="$1"
    local mount_opt="$2"

    echo "---- Cas : $label ($mount_opt) ----" | tee -a "$RESULTS"

    mount -o loop,"$mount_opt" "$IMG" "$MNT"

    local t0 t1 elapsed
    t0=$(date +%s.%N)
    # cp -a préserve xattrs/SELinux context, ce qui peut déclencher une "Erreur d'E/S"
    # sur un montage loop fraîchement créé (observé sur Fedora+SELinux). On copie juste
    # le contenu (mode basique conservé, xattrs/owner/timestamps non préservés) : suffisant
    # pour mesurer la compression, qui ne dépend pas des métadonnées.
    if ! cp -r "$DATASET"/. "$MNT"/; then
        echo "ÉCHEC de la copie pour '$label'. Diagnostic (dmesg) :" >&2
        dmesg | tail -20 | grep -i -E 'btrfs|read-only|enospc' >&2 || dmesg | tail -20 >&2
        exit 1
    fi
    sync
    t1=$(date +%s.%N)
    elapsed=$(echo "$t1 - $t0" | bc)

    echo "Temps de copie + sync : ${elapsed}s" | tee -a "$RESULTS"
    compsize "$MNT" | tee -a "$RESULTS"

    # Test décompression : relire tout et jeter (chrono)
    t0=$(date +%s.%N)
    tar -C "$MNT" -cf /dev/null . 2>/dev/null
    t1=$(date +%s.%N)
    elapsed=$(echo "$t1 - $t0" | bc)
    echo "Temps de lecture complète (tar->/dev/null) : ${elapsed}s" | tee -a "$RESULTS"
    echo "" | tee -a "$RESULTS"

    rm -rf "${MNT:?}"/*
    umount "$MNT"
}

echo "== Dataset original ==" | tee "$RESULTS"
echo "Taille : $(numfmt --to=iec "$DATASET_SIZE")" | tee -a "$RESULTS"
echo "" | tee -a "$RESULTS"

# Échauffement : un premier cycle mount/copie/umount "à blanc" (résultat jeté) pour que
# les 4 mesures suivantes partent toutes d'une image où les chunks btrfs sont déjà
# alloués. Sans ça, le tout premier cas mesuré est systématiquement pénalisé de quelques
# secondes (allocation de chunks, premiers commits d'arbres UUID/free-space) — un biais
# d'ordre, indépendant du niveau de compression testé.
echo "-- Échauffement (résultat non retenu) --"
mount -o loop,compress=zstd:1 "$IMG" "$MNT"
cp -r "$DATASET"/. "$MNT"/ >/dev/null 2>&1 || true
sync
rm -rf "${MNT:?}"/*
umount "$MNT"
echo ""

# Ordre randomisé à chaque exécution, pour qu'un biais résiduel lié à la position
# (1er/2e/3e/4e cas) ne favorise pas systématiquement la même option d'un run à l'autre.
CASES=(
    "compress=zstd:1|compress=zstd:1"
    "compress=zstd:3|compress=zstd:3"
    "compress-force=zstd:1|compress-force=zstd:1"
    "compress-force=zstd:3|compress-force=zstd:3"
)
mapfile -t CASES < <(printf '%s\n' "${CASES[@]}" | shuf)
echo "Ordre de passage pour ce run : ${CASES[*]%%|*}" | tee -a "$RESULTS"
echo "" | tee -a "$RESULTS"

for c in "${CASES[@]}"; do
    label="${c%%|*}"
    opt="${c##*|}"
    run_case "$label" "$opt"
done

echo ""
echo "== Résumé enregistré dans : $RESULTS =="
echo "(le répertoire temporaire sera supprimé à la sortie du script — copie ce fichier si tu veux le garder)"
cp "$RESULTS" /root/btrfs-bench-results.txt 2>/dev/null && echo "Copie sauvegardée : /root/btrfs-bench-results.txt"

echo ""
echo "== Affichage final =="
cat "$RESULTS"
