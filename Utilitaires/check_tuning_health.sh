#!/usr/bin/env bash
#
# check_tuning_health.sh
# Vérifie l'état des réglages de tuning système sur une machine NixOS
# (ntsync, earlyoom, swappiness, zram, compression btrfs, fstrim, discard=async)
#
# Sortie : OK / FAIL / WARN pour chaque point, résumé final avec code de sortie.

set -uo pipefail

# --- Couleurs -----------------------------------------------------------
if [[ -t 1 ]]; then
    C_OK='\033[1;32m'; C_FAIL='\033[1;31m'; C_WARN='\033[1;33m'; C_INFO='\033[1;36m'; C_RESET='\033[0m'
else
    C_OK=''; C_FAIL=''; C_WARN=''; C_INFO=''; C_RESET=''
fi

PASS=0
FAIL=0
WARN=0

ok()   { printf "  ${C_OK}[ OK ]${C_RESET}   %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${C_FAIL}[FAIL]${C_RESET}   %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  ${C_WARN}[WARN]${C_RESET}   %s\n" "$1"; WARN=$((WARN+1)); }
info() { printf "  ${C_INFO}[INFO]${C_RESET}   %s\n" "$1"; }

section() { printf "\n${C_INFO}== %s ==${C_RESET}\n" "$1"; }

need_root_note() {
    if [[ $EUID -ne 0 ]]; then
        printf "${C_WARN}Remarque : certaines vérifications (LUKS, discard) sont plus fiables en root (sudo).${C_RESET}\n\n"
    fi
}

# =========================================================================
section "Module ntsync"
# =========================================================================
if lsmod | grep -q '^ntsync'; then
    ok "Module ntsync chargé (lsmod)"
elif [[ -d /sys/module/ntsync ]]; then
    ok "Module ntsync actif (intégré au noyau, /sys/module/ntsync présent)"
else
    if modinfo ntsync &>/dev/null; then
        fail "Module ntsync disponible mais NON chargé"
    else
        fail "Module ntsync introuvable (ni chargé, ni disponible via modinfo)"
    fi
fi

if [[ -e /dev/ntsync ]]; then
    ok "Périphérique /dev/ntsync présent"
else
    warn "/dev/ntsync absent (nécessaire pour que Wine/Proton l'utilisent réellement)"
fi

# =========================================================================
section "earlyoom"
# =========================================================================
if systemctl is-active --quiet earlyoom 2>/dev/null; then
    ok "Service earlyoom actif (systemd)"
elif pgrep -x earlyoom &>/dev/null; then
    ok "Processus earlyoom en cours d'exécution"
else
    fail "earlyoom n'est ni actif via systemd, ni trouvé en tant que processus"
fi

if systemctl is-enabled --quiet earlyoom 2>/dev/null; then
    ok "Service earlyoom activé au démarrage"
else
    warn "Impossible de confirmer que earlyoom est activé au démarrage (systemctl is-enabled)"
fi

# =========================================================================
section "swappiness (attendu : 150)"
# =========================================================================
SWAPPINESS=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "?")
if [[ "$SWAPPINESS" == "150" ]]; then
    ok "vm.swappiness = 150"
else
    fail "vm.swappiness = ${SWAPPINESS} (attendu : 150)"
fi

# =========================================================================
section "zram"
# =========================================================================
ZRAM_DEV=""
for d in /sys/block/zram*; do
    [[ -d "$d" ]] || continue
    ZRAM_DEV="$d"
    break
done

if [[ -z "$ZRAM_DEV" ]]; then
    fail "Aucun périphérique zram détecté (/sys/block/zram*)"
else
    DEVNAME=$(basename "$ZRAM_DEV")
    info "Périphérique détecté : $DEVNAME"

    # Compression
    if [[ -f "$ZRAM_DEV/comp_algorithm" ]]; then
        COMP=$(cat "$ZRAM_DEV/comp_algorithm" | grep -o '\[[a-z0-9_-]*\]' | tr -d '[]')
        if [[ "$COMP" == "zstd" ]]; then
            ok "Compression zram = zstd"
        else
            fail "Compression zram = ${COMP:-inconnue} (attendu : zstd)"
        fi
    else
        fail "Impossible de lire l'algorithme de compression zram"
    fi

    # Taille (disksize)
    if [[ -f "$ZRAM_DEV/disksize" ]]; then
        SIZE_BYTES=$(cat "$ZRAM_DEV/disksize")
        SIZE_HUMAN=$(numfmt --to=iec-i --suffix=B "$SIZE_BYTES" 2>/dev/null || echo "${SIZE_BYTES} octets")
        info "Taille configurée : ${SIZE_HUMAN}"
    else
        warn "Impossible de lire la taille du zram (disksize)"
    fi

    # Priorité (via swapon)
    if command -v swapon &>/dev/null; then
        PRIO_LINE=$(swapon --show=NAME,PRIO --noheadings 2>/dev/null | grep "/dev/${DEVNAME}")
        if [[ -n "$PRIO_LINE" ]]; then
            PRIO=$(echo "$PRIO_LINE" | awk '{print $2}')
            info "Priorité swap : ${PRIO}"
            ok "zram actif comme swap (priorité ${PRIO})"
        else
            fail "/dev/${DEVNAME} n'apparaît pas comme swap actif (swapon --show)"
        fi
    else
        warn "Commande swapon indisponible, impossible de vérifier la priorité"
    fi
fi

# =========================================================================
section "Compression btrfs (attendu : zstd, niveau 3)"
# =========================================================================
BTRFS_MOUNTS=$(findmnt -t btrfs -n -l -o TARGET 2>/dev/null)

if [[ -z "$BTRFS_MOUNTS" ]]; then
    warn "Aucun montage btrfs détecté"
else
    while IFS= read -r MOUNT; do
        [[ -z "$MOUNT" ]] && continue
        OPTS=$(findmnt -n -o OPTIONS --target "$MOUNT" 2>/dev/null)
        COMPRESS_OPT=$(echo "$OPTS" | grep -o 'compress=[a-z0-9:]*' || echo "$OPTS" | grep -o 'compress-force=[a-z0-9:]*')

        if [[ -z "$COMPRESS_OPT" ]]; then
            fail "$MOUNT : aucune option compress détectée dans les montages"
            continue
        fi

        if echo "$COMPRESS_OPT" | grep -q 'zstd:3'; then
            ok "$MOUNT : ${COMPRESS_OPT}"
        elif echo "$COMPRESS_OPT" | grep -q 'zstd'; then
            LEVEL=$(echo "$COMPRESS_OPT" | grep -oP 'zstd:\K[0-9]+' || echo "défaut (3)")
            if [[ "$LEVEL" == "défaut (3)" ]]; then
                ok "$MOUNT : ${COMPRESS_OPT} (niveau non explicite = défaut zstd:3)"
            else
                warn "$MOUNT : ${COMPRESS_OPT} (niveau ${LEVEL}, attendu 3)"
            fi
        else
            fail "$MOUNT : ${COMPRESS_OPT} (algorithme différent de zstd)"
        fi
    done <<< "$BTRFS_MOUNTS"
fi

# =========================================================================
section "fstrim"
# =========================================================================
if systemctl is-enabled --quiet fstrim.timer 2>/dev/null; then
    ok "fstrim.timer activé"
    if systemctl is-active --quiet fstrim.timer 2>/dev/null; then
        ok "fstrim.timer actif"
    else
        warn "fstrim.timer activé mais pas actif actuellement"
    fi
    LAST_RUN=$(systemctl show fstrim.service -p ExecMainStartTimestamp --value 2>/dev/null)
    if [[ -n "$LAST_RUN" && "$LAST_RUN" != "n/a" ]]; then
        info "Dernière exécution de fstrim.service : ${LAST_RUN}"
    else
        warn "fstrim.service ne semble pas avoir encore été exécuté"
    fi
else
    fail "fstrim.timer non activé (vérifier services.fstrim.enable dans la config NixOS)"
fi

# =========================================================================
section "discard=async (montages + LUKS)"
# =========================================================================
info "Montages filesystem (hors pseudo-fs) :"
# Types de FS à ignorer (pseudo-fs, virtuels, sans notion de TRIM/discard)
EXCLUDED_FSTYPES='^(selinuxfs|rpc_pipefs|tmpfs|devtmpfs|proc|sysfs|cgroup|cgroup2|devpts|overlay|squashfs|efivarfs|debugfs|tracefs|configfs|mqueue|bpf|pstore|securityfs|autofs|hugetlbfs|binfmt_misc|ramfs|fuse\..*|fusectl)$'

FS_MOUNTS=$(findmnt -n -l -o TARGET,FSTYPE,OPTIONS 2>/dev/null)

if [[ -z "$FS_MOUNTS" ]]; then
    warn "Aucun montage exploitable trouvé via findmnt"
else
    while IFS= read -r LINE; do
        [[ -z "$LINE" ]] && continue
        TARGET=$(echo "$LINE" | awk '{print $1}')
        FSTYPE=$(echo "$LINE" | awk '{print $2}')
        OPTS=$(echo "$LINE" | awk '{ $1=""; $2=""; print }' | sed 's/^ *//')

        # Ignorer les pseudo-fs par type réel, pas par texte brut
        if [[ "$FSTYPE" =~ $EXCLUDED_FSTYPES ]]; then
            continue
        fi
        # Ignorer vfat (/boot/efi) : pas de discard=async pertinent sur FAT
        if [[ "$FSTYPE" == "vfat" ]]; then
            continue
        fi

        if echo "$OPTS" | grep -qw 'discard=async'; then
            ok "$TARGET ($FSTYPE) : discard=async"
        elif echo "$OPTS" | grep -qw 'discard'; then
            warn "$TARGET ($FSTYPE) : discard présent mais pas explicitement 'async' (${OPTS})"
        else
            fail "$TARGET ($FSTYPE) : pas de discard actif dans les options de montage"
        fi
    done <<< "$FS_MOUNTS"
fi

echo
info "Périphériques LUKS (dm-crypt) :"
if command -v dmsetup &>/dev/null; then
    LUKS_DEVS=$(dmsetup ls --target crypt 2>/dev/null | awk '{print $1}')
    if [[ -z "$LUKS_DEVS" || "$LUKS_DEVS" == "No devices found" ]]; then
        warn "Aucun périphérique LUKS/dm-crypt détecté"
    else
        while IFS= read -r DEV; do
            [[ -z "$DEV" ]] && continue
            TABLE=$(dmsetup table "$DEV" 2>/dev/null)
            if echo "$TABLE" | grep -qw 'allow_discards'; then
                ok "LUKS ${DEV} : allow_discards actif (TRIM traversant LUKS)"
            else
                fail "LUKS ${DEV} : allow_discards absent (le TRIM ne traverse pas la couche LUKS)"
            fi
        done <<< "$LUKS_DEVS"
    fi
else
    warn "dmsetup indisponible, impossible de vérifier allow_discards sur LUKS"
fi

# =========================================================================
section "Résumé"
# =========================================================================
printf "  ${C_OK}OK: %d${C_RESET}   ${C_WARN}WARN: %d${C_RESET}   ${C_FAIL}FAIL: %d${C_RESET}\n\n" "$PASS" "$WARN" "$FAIL"

if [[ $FAIL -gt 0 ]]; then
    exit 1
elif [[ $WARN -gt 0 ]]; then
    exit 2
else
    exit 0
fi
