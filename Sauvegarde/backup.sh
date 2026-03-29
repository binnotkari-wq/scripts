#!/usr/bin/env bash

cloner_entre_disques_sauvegarde() {
  echo "Il s'agit d'une sauvegarde décrémentielle, d'un disque de sauvegarde vers un autre disque de sauvegarde de sécurité :"
  echo "- La destination est un copie miroir de la source."
  echo "- Ajoute les nouveau fichiers, et déplace les fichiers dépréciés (pour archivage)"
  rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE/Mes-Donnees/" "$DESTINATION/Mes-Donnees" | tee -a "$LOG_FILE"
}

cloner_pc_vers_stockage() {
  echo "lI s'agit d'une sauvegarde décrémentielle des dossiers du PC vers le disque de stockage :"
  echo "- La destination est un copie miroir de la source."
  echo "- Ajoute les nouveau fichiers, et déplace les fichiers dépréciés (pour archivage)"
  SOURCE="/home/benoit/Mes-Donnees"
  rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE" "$DESTINATION" | tee -a "$LOG_FILE"
}

cloner_stockage_vers_pc() {
  echo "lI s'agit d'une sauvegarde décrémentielle des dossiers du PC vers le disque de stockage :"
  echo "- La destination est un copie miroir de la source."
  echo "- Ajoute les nouveau fichiers, et déplace les fichiers dépréciés (pour archivage)"
  SOURCE="/home/benoit/Mes-Donnees"
  rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE" "$DESTINATION" | tee -a "$LOG_FILE"
}

sauvegarder_pc-dossiers-de-travail-seulement_vers_stockage() {
  echo "Il s'agit d'une sauvegarde décrémentielle des dossiers du PC vers le disque de stockage :"
  echo "- La destination est un copie miroir de la source, uniquement pour les dossiers de travail (pc mobile, qui ne contient pas de documents personnels)"
  echo "- Ajoute les nouveau fichiers, et déplace les fichiers dépréciés (pour archivage)"
  SOURCE="/home/benoit/Mes-Donnees"
  rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE/03_Ressources_Externes/" "$DESTINATION/Mes-Donnees/03_Ressources_Externes" | tee -a "$LOG_FILE" &&
  rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE/05_En_Cours/" "$DESTINATION/Mes-Donnees/05_En_Cours" | tee -a "$LOG_FILE" &&
  rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE/99_Technique/" "$DESTINATION/Mes-Donnees/99_Technique" | tee -a "$LOG_FILE" &&
  rsync -avh --delete --backup --backup-dir="$DEPRECATED_DIR" "$SOURCE/Git/" "$DESTINATION/Mes-Donnees/Git" | tee -a "$LOG_FILE"
}

restaurer_stockage_dossiers-de-travail-seulement_vers_pc() {
  SOURCE="/home/benoit/Mes-Donnees"
  mkdir -p "$SOURCE/03_Ressources_Externes" &&
  mkdir -p "$SOURCE/05_En_Cours" &&
  mkdir -p "$SOURCE/99_Technique" &&
  mkdir -p "$SOURCE/Git" &&
  rsync -avh "$DESTINATION/Mes-Donnees/03_Ressources_Externes" "$SOURCE/03_Ressources_Externes/" &&
  rsync -avh "$DESTINATION/Mes-Donnees/05_En_Cours" "$SOURCE/05_En_Cours/" &&
  rsync -avh "$DESTINATION/Mes-Donnees/99_Technique" "$SOURCE/99_Technique/" &&
  rsync -avh "$DESTINATION/Mes-Donnees/Git" "$SOURCE/Git/"
}

sauvegarder_additive_telephone_vers_backup() {
  echo "Il s'agit d'une sauvegarde incrémentielle, depuis le smartphone vers le PC"
  echo "- L'option --size_only est utilisée car Android met à jour les dates de dernières modification, et par defaut rsync considère cela comme une trace de modification réelle."
  echo "- La suppression, modification ou déplacement de fichiers dans le téléphone ne sont pas appliqués à la sauvegarde "
  echo "--> seuls les ajouts sont traités, puisque le téléphone est voué à générer ou collecter des données, et non à travailler dessus."

  # SOURCE="/run/user/1000/a28accf58fa24d9d8936d8d37f4153ce/storage" # KDE
  SOURCE="/run/user/1000/gvfs/mtp:host=Xiaomi_Redmi_Note_11S_AINFN7AIT8E6EAIN" # Gnome

  rsync -avh --progress --size-only "$SOURCE/60FA-E036/DCIM/" "$DESTINATION/Mes-Donnees/01_Souvenirs/Photos/" &&
  rsync -avh --progress --size-only "$SOURCE/60FA-E036/Download/" "$DESTINATION/Mes-Donnees/05_En_Cours/Fiches_A_Travailler/Downloads téléphone/" &&
  rsync -avh --progress --size-only "$SOURCE/60FA-E036/MIUI/sound_recorder/" "$DESTINATION/Mes-Donnees/01_Souvenirs/Dictaphone/" &&
  rsync -avh --progress --size-only "$SOURCE/60FA-E036/Movies/Whatsapp/" "$DESTINATION/Mes-Donnees/01_Souvenirs/WhatsApp/Media/WhatsApp Video" &&
  rsync -avh --progress --size-only "$SOURCE/60FA-E036/Musique/" "$DESTINATION/Mes-Donnees/03_Ressources_Externes/Musique/" &&
  rsync -avh --progress --size-only "$SOURCE/60FA-E036/Pictures" "$DESTINATION/Mes-Donnees/01_Souvenirs/Photos/" &&
  rsync -avh --progress --size-only "$SOURCE/60FA-E036/Android/media/com.whatsapp/WhatsApp/" "$DESTINATION/Mes-Donnees/01_Souvenirs/WhatsApp/" &&
  rsync -avh --progress --size-only "$SOURCE/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/" "$DESTINATION/Mes-Donnees/01_Souvenirs/WhatsApp/" &&
  rsync -avh --progress --size-only "$SOURCE/emulated/0/DCIM/" "$DESTINATION/Mes-Donnees/01_Souvenirs/Photos/" &&
  rsync -avh --progress --size-only "$SOURCE/emulated/0/Download/" "$DESTINATION/Mes-Donnees/05_En_Cours/Fiches_A_Travailler/Downloads téléphone/" &&
  rsync -avh --progress --size-only "$SOURCE/emulated/0/MIUI/sound_recorder/" "$DESTINATION/Mes-Donnees/01_Souvenirs/Dictaphone/" &&
  rsync -avh --progress --size-only "$SOURCE/emulated/0/Movies/Whatsapp/" "$DESTINATION/Mes-Donnees/01_Souvenirs/WhatsApp/Media/WhatsApp Video" &&
  rsync -avh --progress --size-only "$SOURCE/emulated/0/Pictures" "$DESTINATION/Mes-Donnees/01_Souvenirs/Photos/" &&
  rsync -avh --progress --size-only "$SOURCE/emulated/0/Android/media/com.whatsapp/WhatsApp/" "$DESTINATION/Mes-Donnees/01_Souvenirs/WhatsApp/"
}

# ========================================================
# FONCTION GENERALES
# ========================================================


choisir_type_sauvegarde () {
# à faire
echo "à faire"
}


definir_variables_communes() {
  DATE=$(date +'%Y%m%d_%H%M%S')
  DEPRECATED_DIR="$DESTINATION/Dépréciés/$DATE"
  LOG_DIR="$DESTINATION/logs"
  LOG_FILE="$LOG_DIR/sauvegarde_$DATE.log"
  mkdir -p "$DEPRECATED_DIR"
  mkdir -p "$LOG_DIR"
}

annoncer_operation(){
  echo "=========================================================" | tee "$LOG_FILE"
  echo "📦 Sauvegarde lancée le $(date)" | tee -a "$LOG_FILE"
  echo "📁 Source       : $SOURCE" | tee -a "$LOG_FILE"
  echo "💽 Destination  : $DESTINATION" | tee -a "$LOG_FILE"
  echo "🗃️  Fichiers dépréciés : $DEPRECATED_DIR" | tee -a "$LOG_FILE"
  echo "📄 Journal      : $LOG_FILE" | tee -a "$LOG_FILE"
  echo "=========================================================" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
}

detecter_et_choisir_disque_source() {
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
}

detecter_et_choisir_disque_destination() {
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
  echo "========================================================="
  echo ""
}


ecrire_conclusion_dans_log() {
  echo "" | tee -a "$LOG_FILE" &&
  echo "✅ Sauvegarde effectuée le $(date)" | tee -a "$LOG_FILE"
}



# systematique
choisir_type_sauvegarde
definir_variables_communes

# si on veut cloner deux disques de sauvegarde :
detecter_et_choisir_disque_source
detecter_et_choisir_disque_destination
annoncer_operation
cloner_entre_disques_sauvegarde

# si on veut sauvegarder le contenu du pc :
annoncer_operation
sauvegarder_miroir_pc_vers_stockage

# si sauvegarde telephone :
annoncer_operation
sauvegarder_additive_telephone_vers_backup

# systematique
ecrire_conclusion_dans_log
