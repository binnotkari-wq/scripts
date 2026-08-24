#!/usr/bin/env bash
#
# check_system_health.sh
#
# Vérifie si une customisation système récente a été correctement intégrée
# ou si elle provoque des erreurs silencieuses (boot, runtime, shutdown).
# Distro-agnostique : repose uniquement sur systemd/journald.
#
# Usage:
#   ./check_system_health.sh [-b BOOT_OFFSET] [-s SINCE] [-p] [-r] [-R] [-o OUTFILE]
#
#   -b BOOT_OFFSET   Offset de boot à analyser (0 = courant, -1 = précédent). Défaut: 0
#   -s SINCE         Filtre temporel journalctl (ex: "10 min ago"). Optionnel.
#   -p               Inclut aussi le boot précédent (-1) même si -b est fourni.
#   -r               Ajoute la section RUNTIME (état système en cours de fonctionnement).
#   -R               Mode runtime SEUL : saute les sections boot/shutdown/coredump,
#                    ne fait que la section RUNTIME (pratique pour un check rapide
#                    pendant une manip, sans reboot).
#   -o OUTFILE        Écrit le rapport dans un fichier en plus de stdout.
#   -h               Affiche cette aide.
#
# Exemple:
#   ./check_system_health.sh                     # état du boot courant
#   ./check_system_health.sh -b -1                # état du boot précédent (post-reboot)
#   ./check_system_health.sh -s "15 min ago"      # erreurs des 15 dernières minutes
#   ./check_system_health.sh -r -s "10 min ago"   # boot + runtime depuis 10 min
#   ./check_system_health.sh -R                   # runtime seul, check rapide en direct

set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"

BOOT_OFFSET=0
SINCE=""
INCLUDE_PREVIOUS=0
RUNTIME=0
RUNTIME_ONLY=0
OUTFILE=""

# --- Logging tiers (stderr) ---------------------------------------------
log_info()  { printf '[INFO]  %s\n' "$*" >&2; }
log_warn()  { printf '[WARN]  %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

# --- Cleanup --------------------------------------------------------------
TMP_REPORT="$(mktemp)"
cleanup() {
  local exit_code=$?
  rm -f "${TMP_REPORT}"
  if [[ ${exit_code} -ne 0 ]]; then
    log_error "Le script s'est terminé avec le code ${exit_code}"
  fi
  exit "${exit_code}"
}
trap cleanup EXIT

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Argument parsing -------------------------------------------------------
while getopts ":b:s:prRo:h" opt; do
  case "${opt}" in
    b) BOOT_OFFSET="${OPTARG}" ;;
    s) SINCE="${OPTARG}" ;;
    p) INCLUDE_PREVIOUS=1 ;;
    r) RUNTIME=1 ;;
    R) RUNTIME=1; RUNTIME_ONLY=1 ;;
    o) OUTFILE="${OPTARG}" ;;
    h) usage; exit 0 ;;
    \?) log_error "Option invalide: -${OPTARG}"; usage; exit 1 ;;
    :) log_error "L'option -${OPTARG} nécessite un argument"; usage; exit 1 ;;
  esac
done

section() {
  {
    echo ""
    echo "==================================================================="
    echo "  $*"
    echo "==================================================================="
  } | tee -a "${TMP_REPORT}"
}

run_and_capture() {
  # Exécute une commande, l'affiche dans le rapport, ne fait jamais échouer
  # le script global si la commande retourne un code non-nul (ex: grep vide).
  local description="$1"
  shift
  {
    echo "--- ${description} ---"
    if ! "$@" 2>&1; then
      echo "(rien à signaler, ou commande non applicable sur ce système)"
    fi
    echo ""
  } | tee -a "${TMP_REPORT}"
}

runtime_section() {
  section "6. RUNTIME (état système en cours de fonctionnement)"

  run_and_capture "Services systemd en échec (instantané actuel)" \
    systemctl --failed --no-legend --no-pager

  run_and_capture "Services redémarrés en boucle (Scheduled restart job)" \
    bash -c "journalctl --since '${SINCE:-1 hour ago}' --no-pager | grep -i 'Scheduled restart job' || true"

  run_and_capture "Unités actuellement dans un état 'failed' ou 'activating' (boucle possible)" \
    bash -c "systemctl list-units --state=failed,activating --no-legend --no-pager || true"

  run_and_capture "Consommation CPU/mémoire par cgroup (instantané, 1 passage)" \
    bash -c "systemd-cgtop -b -n 1 --order=cpu 2>&1 | head -n 20 || true"

  run_and_capture "Erreurs journal depuis '${SINCE:-30 min ago}' (priorité err)" \
    journalctl --since "${SINCE:-30 min ago}" -p err --no-pager

  run_and_capture "OOM killer / pressions mémoire récentes" \
    bash -c "journalctl --since '${SINCE:-1 hour ago}' --no-pager | grep -iE 'out of memory|oom-kill|killed process' || true"

  run_and_capture "Espace disque réel (composefs / est un instantané figé en lecture seule, non pertinent ; on regarde /var à la place)" \
    bash -c "df -hT | grep -v -E 'composefs|overlay' || df -h /var"
}

main() {
  log_info "Analyse du boot offset=${BOOT_OFFSET}$( [[ -n "${SINCE}" ]] && echo ", depuis '${SINCE}'" )$( [[ "${RUNTIME}" -eq 1 ]] && echo ", runtime activé" )"

  if [[ "${RUNTIME_ONLY}" -ne 1 ]]; then
    section "1. SERVICES EN ÉCHEC (systemctl --failed)"
    run_and_capture "Services systemd en échec" systemctl --failed --no-legend --no-pager

    section "2. ERREURS JOURNALCTL (priorité err et au-dessus)"
    if [[ -n "${SINCE}" ]]; then
      run_and_capture "journalctl --since '${SINCE}' -p err" \
        journalctl --since "${SINCE}" -p err --no-pager
    else
      run_and_capture "journalctl -b ${BOOT_OFFSET} -p err" \
        journalctl -b "${BOOT_OFFSET}" -p err --no-pager
    fi

    if [[ "${INCLUDE_PREVIOUS}" -eq 1 && "${BOOT_OFFSET}" -eq 0 ]]; then
      run_and_capture "journalctl -b -1 -p err (boot précédent)" \
        journalctl -b -1 -p err --no-pager
    fi

    section "3. NIVEAU KERNEL (dmesg / journalctl -k, en secours si non-persistant)"
    if journalctl -k -b "${BOOT_OFFSET}" --no-pager 2>/dev/null | grep -qi .; then
      run_and_capture "journalctl -k -b ${BOOT_OFFSET} (erreurs kernel)" \
        journalctl -k -b "${BOOT_OFFSET}" -p err --no-pager
    else
      log_warn "journal kernel indisponible pour ce boot, repli sur dmesg (boot courant uniquement)"
      run_and_capture "dmesg -T -l err,crit,alert,emerg" \
        dmesg -T -l err,crit,alert,emerg
    fi

    section "4. EXTINCTION / ARRÊT PROPRE DU BOOT PRÉCÉDENT"
    run_and_capture "Dernières lignes du boot -1 (séquence de shutdown)" \
      journalctl -b -1 -e -n 40 --no-pager
    run_and_capture "Recherche de timeouts ou démontages échoués" \
      bash -c "journalctl -b -1 --no-pager | grep -iE 'timed out|failed to unmount|failed to stop' || true"

    section "5. COREDUMPS (crashs / arrêts non propres)"
    run_and_capture "coredumpctl list (10 derniers)" \
      coredumpctl list --no-pager -n 10
  fi

  if [[ "${RUNTIME}" -eq 1 ]]; then
    runtime_section
  fi

  section "RÉSUMÉ"
  {
    echo "Rapport généré le $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "Pense à comparer ce rapport avec celui d'un système d'origine non customisé."
  } | tee -a "${TMP_REPORT}"

  if [[ -n "${OUTFILE}" ]]; then
    cp "${TMP_REPORT}" "${OUTFILE}"
    log_info "Rapport écrit dans ${OUTFILE}"
  fi
}

main "$@"
