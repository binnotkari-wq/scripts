#!/bin/bash

# Post install d'après https://wiki.debian.org/fr/DebianInstall

echo "========================================================="
# Message de présentation
echo "Vérification de sudo, mise à jour du système, ajout de l'ISO en tant que source de logiciel puis installation de Timeshift"

sleep 2

echo "========================================================="
#Vous pouvez vérifier le succès de ce qui précède en entrant
echo "1. Vérification de l'enregistrement de l'utilisateur dans le groupe sudo :"
sleep 1
groups

sleep 2

echo "========================================================="
# Il est de bonne pratique de mettre à jour son installation immédiatement 
echo "2. Mise à jour du système :"
sleep 1
sudo apt update && sudo apt upgrade

sleep 2

# echo "========================================================="
# Ajout de l'image ISO du Blu-Ray en tant que source d'installation offline (adapter selon le nom de l'ISO):
# sudo mount -o loop "$HOME/opt/debian-12.11.0-amd64-BD-1.iso" "/media/cdrom/"
# L'opération suivante permet de ne pas avoir à utiliser "sudo apt-cdrom -m -d="/media/cdrom" add" car apt-cdrom ne qualifie pas la source en "trusted=yes"
# echo "deb [trusted=yes] cdrom:[Debian GNU/Linux 12.11.0 _Bookworm_ - Official amd64 BD Binary-1 with firmware 20250517-09:53]/ bookworm contrib main non-free-firmware" | sudo tee -a /etc/apt/sources.list

# sleep 2

echo "========================================================="
echo "Installation de Timeshift."
# Installer Timeshift avant toute autre chose et Faire une sauvegarde du système, d'après le tuto de ChatGPT
sudo apt update
sudo apt install timeshift

sleep 2

echo "========================================================="
# Annonce de redémarrage
echo "L'ordinateur va redémarrer. Il faut faire une sauvegarde Timeshift après le redémarrage."
sleep 5
sudo systemctl reboot
exit
