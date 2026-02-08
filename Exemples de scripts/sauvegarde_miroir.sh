#!/bin/bash

echo "Sauvegarde : Miroir de Source vers Backup1 ou Backup2)"

sleep 2

read -p "Procéder à la sauvegarde? (o/n) " choice
case $choice in
	[Oo]* ) rsync -avh --progress --delete "/media/benoit/Source/Benoit/" "/media/benoit/Backup 2/Benoit";;
	* ) echo "Abandon";;
esac

sleep 2

echo "Terminé"
echo "========================================================="

