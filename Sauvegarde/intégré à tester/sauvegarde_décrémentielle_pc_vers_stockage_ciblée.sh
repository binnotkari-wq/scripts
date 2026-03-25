#!/usr/bin/env bash

echo ""
echo "========================================================="
echo "Il s'agit d'une sauvegarde décrémentielle des dossiers du PC vers le disque de stockage :"
echo "- La destination est un copie miroir de la source" 
echo "- Ajoute les nouveau fichiers, et déplace les fichiers dépréciés (qui n'existent plus dans la sources : soit parce qu'ils ont été modifiés, soit parce qu'il ont été déplacés ou supprimés) dans le répertoire dépréciés+date."
echo "-> ce qui permet de vérifier avant de supprimer définitivement les fichiers dépréciés"
echo "========================================================="
echo ""


# === Définition des répertoire de sources, destination, des fichiers dépréciés et du log ===
HOME_DIR="/home/benoit"
SAVE_DIR="/run/media/benoit/Stockage"
USER_DIR="Mes-Donnees"
DATE=$(date +'%Y%m%d_%H%M%S')
DEPRECATED_DIR="$SAVE_DIR/Dépréciés/$DATE"
LOG_DIR="$SAVE_DIR/logs"
LOG_FILE="$LOG_DIR/sauvegarde_$DATE.log"


mkdir -p "$DEPRECATED_DIR"
mkdir -p "$LOG_DIR"

# === Lancement de la sauvegarde ===
echo "=========================================================" | tee "$LOG_FILE"
echo "📦 Sauvegarde lancée le $(date)" | tee -a "$LOG_FILE"
echo "📁 Source       : $HOME_DIR/$USER_DIR" | tee -a "$LOG_FILE"
echo "💽 Destination  : $SAVE_DIR/$USER_DIR" | tee -a "$LOG_FILE"
echo "🗃️  Fichiers dépréciés : $DEPRECATED_DIR" | tee -a "$LOG_FILE"
echo "📄 Journal      : $LOG_FILE" | tee -a "$LOG_FILE"
echo "=========================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"


read -p "Procéder à la sauvegarde? (o/n) " choice
echo "========================================================="
case $choice in
	[Oo]* ) rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Fiches vie pratique/" "$SAVE_DIR/$USER_DIR/03_Ressources_Externes/Fiches vie pratique" | tee -a "$LOG_FILE" &&
		rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Utilisation du système/" "$SAVE_DIR/$USER_DIR/03_Ressources_Externes/Utilisation du système" | tee -a "$LOG_FILE" &&
		rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Musique/00 vrac/" "$SAVE_DIR/$USER_DIR/03_Ressources_Externes/Musique/00 vrac" | tee -a "$LOG_FILE" &&
		rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$HOME_DIR/$USER_DIR/05_En_Cours/" "$SAVE_DIR/$USER_DIR/05_En_Cours" | tee -a "$LOG_FILE" &&
		rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$HOME_DIR/$USER_DIR/Git/" "$SAVE_DIR/$USER_DIR/Git" | tee -a "$LOG_FILE" &&
		rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$HOME_DIR/$USER_DIR/99_Technique/" "$SAVE_DIR/$USER_DIR/99_Technique" | tee -a "$LOG_FILE" &&
		echo "" | tee -a "$LOG_FILE" &&
		echo "✅ Sauvegarde effectuée le $(date)" | tee -a "$LOG_FILE";;

	* ) echo "Abandon";;
esac

echo "Terminé"
echo "========================================================="
