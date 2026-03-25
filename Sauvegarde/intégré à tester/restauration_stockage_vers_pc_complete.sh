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
	[Oo]* ) mkdir -p "$HOME_DIR/$USER_DIR" &&
		rsync -avh "$SAVE_DIR/$USER_DIR/" "$HOME_DIR/$USER_DIR" &&
		echo "" &&
		echo "✅ Restauration effectuée";;
	* ) echo "Abandon";;
esac

echo "Terminé"
echo "========================================================="
