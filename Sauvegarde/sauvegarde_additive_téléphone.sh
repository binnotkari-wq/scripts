#!/bin/bash

echo ""
echo "========================================================="
echo "Sauvegarde : depuis le smartphone vers disque de sauvegarde. Les nouveaux fichiers du téléphone sont ajoutés au disque de sauvegarde."
echo "La suppression ou modification ou déplacement de fichiers dans le téléphone ne sont pas appliqués à la source (puisque le téléphone est voué à générer ou collecter des données, et non à travailler dessus)."
echo "L'option --size_only est utilisée car Android met à jour les dates de dernières modification, et par defaut rsync considère cela comme une trace de modification réelle."
echo "========================================================="
echo ""

# Racine du Smartphone :

# Pour GNOME (avec GVFS)
# Smartphone="/run/user/1000/gvfs/mtp:host=Xiaomi_Redmi_Note_11S_AINFN7AIT8E6EAIN"

# Pour KDE (avec KDE Connect)
Smartphone="/run/user/1000/a28accf58fa24d9d8936d8d37f4153ce/storage"

# Racine de la sauvegarde :
Save_device="/media/benoit/Stockage/Mes-Donnees"


echo "Les dossier suivants sont sauvegardés :"
echo "1) depuis la carte SD : $Smartphone/60FA-E036/"
echo DCIM
echo Download
echo MIUI
echo Movies
echo Musique
echo Pictures
echo WhatsApp

echo ""

echo "2) depuis la mémoire interne : $Smartphone/emulated/"
echo Android/media/com.whatsapp/WhatsApp/Media
echo DCIM
echo Download
echo MIUI
echo Movies
echo Pictures
echo WhatsApp


echo "========================================================="
read -p "Procéder à la sauvegarde? (o/n) " choice
echo "========================================================="
case $choice in
	[Oo]* ) rsync -avh --progress --size-only "$Smartphone/60FA-E036/DCIM/" "$Save_device/01_Souvenirs/Photos/" &&
		rsync -avh --progress --size-only "$Smartphone/60FA-E036/Download/" "$Save_device/05_En_Cours/Fiches_A_Travailler/Downloads téléphone/" &&
		rsync -avh --progress --size-only "$Smartphone/60FA-E036/MIUI/sound_recorder/" "$Save_device/01_Souvenirs/Dictaphone/" &&
		rsync -avh --progress --size-only "$Smartphone/60FA-E036/Movies/Whatsapp/" "$Save_device/01_Souvenirs/WhatsApp/Media/WhatsApp Video" &&
		rsync -avh --progress --size-only "$Smartphone/60FA-E036/Musique/" "$Save_device/03_Ressources_Externes/Musique/" &&
		rsync -avh --progress --size-only "$Smartphone/60FA-E036/Pictures" "$Save_device/01_Souvenirs/Photos/" &&
		rsync -avh --progress --size-only "$Smartphone/60FA-E036/Android/media/com.whatsapp/WhatsApp/" "$Save_device/01_Souvenirs/WhatsApp/" &&
		rsync -avh --progress --size-only "$Smartphone/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/" "$Save_device/01_Souvenirs/WhatsApp/" &&
		rsync -avh --progress --size-only "$Smartphone/emulated/0/DCIM/" "$Save_device/01_Souvenirs/Photos/" &&
		rsync -avh --progress --size-only "$Smartphone/emulated/0/Download/" "$Save_device/05_En_Cours/Fiches_A_Travailler/Downloads téléphone/" &&
		rsync -avh --progress --size-only "$Smartphone/emulated/0/MIUI/sound_recorder/" "$Save_device/01_Souvenirs/Dictaphone/" &&
		rsync -avh --progress --size-only "$Smartphone/emulated/0/Movies/Whatsapp/" "$Save_device/01_Souvenirs/WhatsApp/Media/WhatsApp Video" &&
		rsync -avh --progress --size-only "$Smartphone/emulated/0/Pictures" "$Save_device/01_Souvenirs/Photos/" &&
		rsync -avh --progress --size-only "$Smartphone/emulated/0/Android/media/com.whatsapp/WhatsApp/" "$Save_device/01_Souvenirs/WhatsApp/";;
	* ) echo "Abandon";;
esac

echo "Terminé"
echo "========================================================="
