### NE PAS UTILISER, EXEMPLE QUI A SERVI A INSPIRER LE SCRIPT DEFINITIF


#!/bin/bash

# Il s'agit d'une sauvegarde décrémentielle. La destination est un copie miroir de la source. Les fichiers dépréciés de la destination (modifiés, supprimés de leur emplacement) sont mis de côté dans le répertoire "Dépréciés_date actuelle" de la destination.

# === Configuration générale ===
SRC="$HOME/Mes-Donnees/"
LABEL="Mes-Donnees_backup"
DATE=$(date +'%Y%m%d_%H%M%S')

# === Détection des disques externes montés et choix du disque de destination ===
echo "Détection des périphériques montés dans /media/$USER ..."
mapfile -t MOUNTED < <(find "/media/$USER" -mindepth 1 -maxdepth 1 -type d)

if [ ${#MOUNTED[@]} -eq 0 ]; then
    echo "Aucun disque monté détecté dans /media/$USER"
    exit 1
fi

echo "Sélectionne le disque de destination :"
select DISK in "${MOUNTED[@]}"; do
    if [[ -n "$DISK" ]]; then
        break
    else
        echo "Choix invalide."
    fi
done

DST="$DISK/$LABEL"
#BACKUP_DIR="$backup_$DATE"
BACKUP_DIR="$DISK/Dépréciés_$DATE"
#BACKUP_DIR="$DST/backup_$DATE"
LOG_DIR="$DISK/logs"
LOG_FILE="$LOG_DIR/sauvegarde_$DATE.log"

# === Préparatifs ===
if [ ! -d "$SRC" ]; then
    echo "Erreur : le dossier source n'existe pas : $SRC" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

# === Lancement de la sauvegarde ===
echo "-------------------------------------------------" | tee "$LOG_FILE"
echo "📦 Sauvegarde lancée le $(date)" | tee -a "$LOG_FILE"
echo "📁 Source       : $SRC" | tee -a "$LOG_FILE"
echo "💽 Destination  : $DST" | tee -a "$LOG_FILE"
echo "🗃️  Fichiers dépréciés : $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "📄 Journal      : $LOG_FILE" | tee -a "$LOG_FILE"
echo "-------------------------------------------------" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

rsync -av --delete \
      --backup \
      --backup-dir="$BACKUP_DIR" \
      "$SRC" "$DST" \
      | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "✅ Sauvegarde terminée le $(date)" | tee -a "$LOG_FILE"

