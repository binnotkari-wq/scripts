#!/bin/bash

# Post install d'après https://wiki.debian.org/fr/DebianInstall

echo "========================================================="
# Message de présentation
echo "Activation de sudo après une nouvelle installation de Debian"

sleep 2

echo "========================================================="
# Pour activer sudo après une nouvelle installation de Debian : 
su -l
adduser $USERNAME sudo

sleep 2

echo "========================================================="
# Annonce de redémarrage
echo "L'ordinateur va redémarrer pour enregistrer l'appartenance de l'utilisateur au groupe sudo."
sleep 5
sudo systemctl reboot
exit
