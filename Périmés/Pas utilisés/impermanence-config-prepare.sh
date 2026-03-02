#!/usr/bin/env bash

# A utiliser si on met en place une impermanence sur un Nixos déjà installé (il faut au moins une partition ou sous volume / et une partition ou sous-volume /nix). IL va de pair avec impermanence-config.nix (dans lequel il faut toutefois indiquer /nix/persist/ comme dossier de persistence, au lieu de /persist en tant que partition ou sous-volume).
# Ce script copie les fichiers à persister dans le dossier dédié à la persistance. Le module impermanence s'occupe de la création des bind mounts, mais ne copie pas au préalable le contenu

set -euo pipefail

PERSIST="/nix/persist"

echo ">>> Vérification de ${PERSIST}"

if [ ! -d "${PERSIST}" ]; then
  echo "ERREUR : ${PERSIST} n'existe pas ou n'est pas monté."
  exit 1
fi

echo ">>> Migration en cours..."

# --- Dossiers ---
migrate_dir() {
  SRC="$1"
  DST="${PERSIST}${SRC}"

  echo ">>> Traitement dossier ${SRC}"

  mkdir -p "$(dirname "${DST}")"

  if [ ! -d "${DST}" ]; then
    cp -a "${SRC}" "${DST}"
  else
    echo "    Déjà présent, ignoré."
  fi
}

migrate_dir /home
migrate_dir /etc/nixos
migrate_dir /etc/NetworkManager/system-connections
migrate_dir /var/lib/bluetooth
migrate_dir /var/lib/cups
migrate_dir /var/lib/fwupd
migrate_dir /var/lib/NetworkManager
migrate_dir /var/lib/nixos

# --- Fichiers ---
migrate_file() {
  SRC="$1"
  DST="${PERSIST}${SRC}"

  echo ">>> Traitement fichier ${SRC}"

  mkdir -p "$(dirname "${DST}")"

  if [ ! -e "${DST}" ]; then
    cp -a "${SRC}" "${DST}"
  else
    echo "    Déjà présent, ignoré."
  fi
}

migrate_file /etc/machine-id
migrate_file /etc/shadow
migrate_file /etc/passwd
migrate_file /etc/group

echo ">>> Migration terminée avec succès."
echo ">>> Vérifie maintenant le contenu de ${PERSIST} avant d'activer tmpfs."
