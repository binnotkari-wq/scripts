#!/usr/bin/env bash

echo ""
echo "========================================================="
echo "Restauration des données depuis le disque de sauvegarde"
echo "========================================================="
echo ""


# === Définition des répertoire de sources et destination ===
HOME_DIR=$HOME
SAVE_DIR="/run/media/benoit/Stockage"
USER_DIR="Mes-Donnees"


# === Lancement de la sauvegarde ===
echo "========================================================="
echo "📁 Source       : $SAVE_DIR/$USER_DIR"
echo "💽 Destination  : $HOME_DIR/$USER_DIR"
echo "========================================================="
echo ""


read -p "Procéder à la sauvegarde? (o/n) " choice
echo "========================================================="
case $choice in
	[Oo]* ) mkdir -p "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Fiches vie pratique" &&
		mkdir -p "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Kiwix zims" &&
		mkdir -p "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Utilisation du système" &&
		mkdir -p "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Musique/00 vrac" &&
		mkdir -p "$HOME_DIR/$USER_DIR/05_En_Cours" &&
		mkdir -p "$HOME_DIR/$USER_DIR/99_Technique" &&
		rsync -avh "$SAVE_DIR/$USER_DIR/03_Ressources_Externes/Fiches vie pratique/" "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Fiches vie pratique" &&
		rsync -avh "$SAVE_DIR/$USER_DIR/03_Ressources_Externes/Kiwix zims/" "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Kiwix zims" &&
		rsync -avh "$SAVE_DIR/$USER_DIR/03_Ressources_Externes/Utilisation du système/" "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Utilisation du système" &&
		rsync -avh "$SAVE_DIR/$USER_DIR/03_Ressources_Externes/Musique/00 vrac/" "$HOME_DIR/$USER_DIR/03_Ressources_Externes/Musique/00 vrac" &&
		rsync -avh "$SAVE_DIR/$USER_DIR/05_En_Cours/" "$HOME_DIR/$USER_DIR/05_En_Cours" &&
		rsync -avh "$SAVE_DIR/$USER_DIR/99_Technique/" "$HOME_DIR/$USER_DIR/99_Technique" &&
		echo "" &&
		echo "✅ Restauration effectuée";;

	* ) echo "Abandon";;
esac

echo "Terminé"
echo "========================================================="
