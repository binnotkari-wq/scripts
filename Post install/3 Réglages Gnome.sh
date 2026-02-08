echo "========================================================="
echo Création des modèles de documents disponible en clic-droit dans Nautilus
read -p "Appuyer sur la touche entrée pour continuer"
touch ~/Modèles/Fichier_texte.txt
touch ~/Modèles/Fichier_Markdown.md

sleep 5

echo "========================================================="
echo Définition de Firefox comme viewer par défaut du code .html généré depuis le terminal
export BROWSER=firefox

sleep 5

# echo "========================================================="
# echo "Eviter le freeze de la caculatrice présent uniquement dans Debian 12"
# read -p "Le système d'exploitation actuel est-il Debian 12? (o/n) " choice
# case $choice in
#	[Oo]* ) gsettings set org.gnome.calculator refresh-interval 0;;
#	* ) echo "Réglage non nécessaire";;
# esac

# sleep 5

# Activer SMB 1.0 pour pouvoir accéder au partage réseau du disque dur de la box red
# vu sur : https://forums.debian.net/viewtopic.php?t=158196

# echo "========================================================="
# echo "Activer SMB 1.0 pour pouvoir accéder au partage réseau du disque dur de la box red"

# sleep 2

# echo "========================================================="
# echo "Création répertoire et fichier de configuration SMB"
# cd 
# mkdir .smb2
# cd .smb
# touch smb.conf

# sleep 2

# echo "========================================================="
# echo "Configuration de ~/.smb/smb.conf : client min protocol = NT1"
# cat > ~/.smb/smb.conf << EOF
# [global]
# client min protocol = NT1
# EOF
# echo "========================================================="

# sleep 5

echo "Terminé"
echo "========================================================="
