#!/usr/bin/env bash
#
# sort_by_album.sh
#
# Classe les fichiers audio d'un dossier dans des sous-dossiers nommés
# d'après leur tag "album", en se basant sur ffprobe (ffmpeg) pour lire
# les métadonnées.
#
# Usage:
#   ./sort_by_album.sh <dossier_source> [--dry-run]
#
# Exemple:
#   ./sort_by_album.sh ~/Musique/Harry\ Potter\ Soundtrack
#   ./sort_by_album.sh ~/Musique/Harry\ Potter\ Soundtrack --dry-run

set -o errexit
set -o nounset
set -o pipefail

readonly SCRIPT_NAME="$(basename "${0}")"

# Extensions audio prises en charge.
readonly AUDIO_EXTENSIONS=("m4a" "mp3" "flac" "ogg" "opus" "wav")

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} <dossier_source> [--dry-run]

  <dossier_source>   Dossier contenant les fichiers audio à classer.
  --dry-run          Affiche les déplacements prévus sans les exécuter.
EOF
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local source_dir="${1}"
  local dry_run="false"

  if [[ "${2:-}" == "--dry-run" ]]; then
    dry_run="true"
  fi

  if [[ ! -d "${source_dir}" ]]; then
    echo "Erreur : '${source_dir}' n'est pas un dossier valide." >&2
    exit 1
  fi

  if ! command -v ffprobe &>/dev/null; then
    echo "Erreur : ffprobe est introuvable. Installe ffmpeg (nix-shell -p ffmpeg)." >&2
    exit 1
  fi

  # Construction du pattern find pour les extensions.
  local find_args=()
  local ext
  for ext in "${AUDIO_EXTENSIONS[@]}"; do
    find_args+=(-o -iname "*.${ext}")
  done
  # Retire le premier -o superflu.
  find_args=("${find_args[@]:1}")

  local file_count=0
  local moved_count=0
  local skipped_count=0

  while IFS= read -r -d '' filepath; do
    ((file_count += 1))

    local album
    album="$(ffprobe -v error -show_entries format_tags=album \
      -of default=noprint_wrappers=1:nokey=1 "${filepath}" 2>/dev/null || true)"

    # Nettoyage : espace superflu, slash interdit dans les noms de dossier.
    album="$(echo -n "${album}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '/' '-')"

    if [[ -z "${album}" ]]; then
      echo "  [ignoré] Pas de tag album : $(basename "${filepath}")"
      ((skipped_count += 1))
      continue
    fi

    local target_dir="${source_dir}/${album}"
    local filename
    filename="$(basename "${filepath}")"

    if [[ "${dry_run}" == "true" ]]; then
      echo "  [dry-run] '${filename}' -> '${album}/'"
    else
      mkdir -p "${target_dir}"
      # Évite d'écraser un fichier si déjà présent (ex: relance du script).
      if [[ -e "${target_dir}/${filename}" ]]; then
        echo "  [déjà présent] '${album}/${filename}'"
      else
        mv -- "${filepath}" "${target_dir}/"
        echo "  [déplacé] '${filename}' -> '${album}/'"
      fi
    fi

    ((moved_count += 1))
  done < <(find "${source_dir}" -maxdepth 1 -type f \( "${find_args[@]}" \) -print0)

  echo ""
  echo "Terminé : ${file_count} fichier(s) analysé(s), ${moved_count} classé(s), ${skipped_count} sans tag album."
  if [[ "${dry_run}" == "true" ]]; then
    echo "(mode dry-run : rien n'a été déplacé, relance sans --dry-run pour appliquer)"
  fi
}

main "$@"
