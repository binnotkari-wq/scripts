#dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all
#Redemarrage, puis :
#dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all
#Redemarrage, puis :
#wsl --set-default-version 2


#!/bin/bash
echo Si les répertoire sont déjà existants, ignorer l\'erreur mkdir.Si aucune sauvegarde incrémentielle hardlink n\'a jamais été faite, on peut ignorer les erreurs sur ls.
#Emplacement du dossier à sauvegarder (modifiable)
#SOURCE=/home/data/
SOURCE=/mnt/d/Benoit2/

#Emplacement du dossier de sauvegarde  (modifiable)
#CIBLE=/media/benoit/Sauvegarde/home/data
CIBLE=/mnt/e/Benoit

#Au cas où ce dossier n'existe pas encore...
mkdir -p $CIBLE

#Nom du projet de sauvegarde (modifiable)
PROJET=User

#Obtention de la date et heure actuelle. Cette variable servira à nommer la sauvegarde qui va être créé.
COURANTE=`(date +%Y-%m-%d_%H.%M.%S)`

#INCREMENTEIL AVEC HARDLINK
#Obtention du nom de la sauvegarde existante la plus récente dans le cas de la sauvegarde incrémentielle (ou de la sauvegarde initiale dans le cas d'un différentiel).
#On stocke en variable uniquement la partie datée du nom (grâce à cut) du dernier répertoire (ou du premier pour le differentiel) de sauvegarde existant (grâce à ls -dr qui ne listera que les répertoires qui nous interressent)
#puis head (qui fait un tri en gardant le nom le plus "haut" donc dans ce cas de figure le nom qui contiendra la date la plus récente) .
#Cette variable sera passée à rsync pour lui indiquer le chemin de la dernière (ou première!) sauvegarde à comparer. 
#DERNIERE=`ls -dr $CIBLE/*$PROJET@* | head -n1 | cut -d'@' -f2`
#PREMIERE=`ls -d $CIBLE/*$PROJET@* | head -n1 | cut -d'@' -f2`
#Si il n'y a pas encore eu de sauvegarde, rsync considère que tout est à copier. Si il y a déjà eu une sauvegarde (c'est à dire si le dossier indiqué dans link-dest est existant) rsync ne synchronisera que les fichiers modifiés / créés / supprimeé. Tous les fichiers et dossiers identiques sont pointés par rsync en harlinks, donc ne prennent pas de place. Donc dans chaque sauvegarde incrémentielle, on a accès à l'ensemble des fichiers et répertoires, pas seulement les fichiers modifiés/créés/supprimés.
#OPT=' -avh --delete'
#rsync $OPT --link-dest=$CIBLE/$PROJET'@'$DERNIERE $SOURCE $CIBLE/$PROJET'@'$COURANTE



#DECREMENTIEL
#OPT='-avh --delete --backup'
#rsync $OPT --backup-dir=$CIBLE/'Dépréciés@'$COURANTE $SOURCE $CIBLE/$PROJET
#avec cette ligne, on a un répértoire qui est l'exacte réplique, et est toujours nommé de façon identique : selon la valeur de "$PROJET". A chaque fois que ce miroir est modifié, du fait de l'activité de la source, les fichiers et répertoires devenus périmés sont sauvegardés pour historique dans "Dépréciés".


#Synchronisation de deux répertoires, sans suppressions dans la cible (testé le 17/05/2020, ok)
#Le u dans l'option sert à ignorer un fichier plus récent dans la cible. Le a est pour archivageDans le cas d'un synchronisation bidirectionnelle, il faut retirer ces option
#OPT='-auv'
OPT='-av'
ORIGINE=/mnt/d/Benoit2/
DESTINATION=/mnt/e/Benoit
rsync $OPT $ORIGINE $DESTINATION

