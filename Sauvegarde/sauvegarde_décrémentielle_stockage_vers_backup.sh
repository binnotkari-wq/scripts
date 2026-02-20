#!/bin/bash

echo ""
echo "========================================================="
echo "Il s'agit d'une sauvegarde décrémentielle :"
echo "- La destination est un copie miroir de la source" 
echo "- Ajoute les nouveau fichiers, et déplace les fichiers dépréciés (qui n'existent plus dans la sources : soit parce qu'ils ont été modifiés, soit parce qu'il ont été déplacés ou supprimés) dans le répertoire dépréciés+date."
echo "-> ce qui permet de vérifier avant de supprimer définitivement les fichiers dépréciés"
echo "========================================================="
echo ""

# === Détection des disques externes montés et choix de la source ===
echo "Détection des périphériques montés dans /media/$USER ..."
mapfile -t MOUNTED < <(find "/media/$USER" -mindepth 1 -maxdepth 1 -type d)

if [ ${#MOUNTED[@]} -eq 0 ]; then
    echo "Aucun disque monté détecté dans /media/$USER"
    exit 1
fi

echo "Sélectionne le disque de source :"
select SOURCE in "${MOUNTED[@]}"; do
    if [[ -n "$SOURCE" ]]; then
        break
    else
        echo "Choix invalide."
    fi
done
echo "========================================================="
echo ""


# === Détection des disques externes montés et choix de la destination ===
echo "Détection des périphériques montés dans /media/$USER ..."
mapfile -t MOUNTED < <(find "/media/$USER" -mindepth 1 -maxdepth 1 -type d)

if [ ${#MOUNTED[@]} -eq 0 ]; then
    echo "Aucun disque monté détecté dans /media/$USER"
    exit 1
fi

echo "Sélectionne le disque de destination :"
select DESTINATION in "${MOUNTED[@]}"; do
    if [[ -n "$DESTINATION" ]]; then
        break
    else
        echo "Choix invalide."
    fi
done

# === Définition du répertoire des fichiers dépréciés et du log ===
DATE=$(date +'%Y%m%d_%H%M%S')
USER_DIR="Mes-Donnees"
DEPRECATED_DIR="$DESTINATION/Dépréciés_$DATE"
LOG_DIR="$DESTINATION/logs"
LOG_FILE="$LOG_DIR/sauvegarde_$DATE.log"


mkdir -p "$DEPRECATED_DIR"
mkdir -p "$LOG_DIR"

# === Lancement de la sauvegarde ===
echo "=========================================================" | tee "$LOG_FILE"
echo "📦 Sauvegarde lancée le $(date)" | tee -a "$LOG_FILE"
echo "📁 Source       : $SOURCE/$USER_DIR" | tee -a "$LOG_FILE"
echo "💽 Destination  : $DESTINATION/$USER_DIR" | tee -a "$LOG_FILE"
echo "🗃️  Fichiers dépréciés : $DEPRECATED_DIR" | tee -a "$LOG_FILE"
echo "📄 Journal      : $LOG_FILE" | tee -a "$LOG_FILE"
echo "=========================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"


read -p "Procéder à la sauvegarde? (o/n) " choice
echo "========================================================="
case $choice in
	[Oo]* ) rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE/$USER_DIR/" "$DESTINATION/$USER_DIR" | tee -a "$LOG_FILE" &&
		echo "" | tee -a "$LOG_FILE" &&
		echo "✅ Sauvegarde effectuée le $(date)" | tee -a "$LOG_FILE";;
		
	* ) echo "Abandon";;
esac

echo "Terminé"
echo "========================================================="
