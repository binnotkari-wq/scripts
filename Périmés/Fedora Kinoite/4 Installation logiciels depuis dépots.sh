#!/bin/bash

# Dans le panneau de configuration, aller dans cavier, et activer "vérrouillage numérique au demarrage"


echo "========================================================="
# Message de présentation
echo "Ce script va installer les logiciels QT suivants :
- GPT4ALL
- Heroic Game Launcher : lanceur de jeux, et permet de lancer et installer n'importe quelle app
- kate : éditeur de texte avancé
- KDiff3 : comparaison de fichiers et répertoires
- KeePassXC : portefeuille de mots de passe
- kiwix
- ktorrent
- libreoffice
- qownnotes : prise de note, export en formats multiples (dont .Md)
- marble : comme google earth
- steam
- virt-manager : modules de virtualisation
- Warzone 2100 : STR natif linux
"

#trouver un moyen de prioriser les depots fedora, et seulement ensuite flathub
flatpak install flathub gpt4all heroic kate KDiff3 KeePassXC kiwix ktorrent libreoffice qownnotes marble steam net.wz2100.wz2100

# virtualisation en espace user : https://zihad.com.bd/posts/virt-manager-in-fedora-silverblue-kinoite-atomic/
# si plusieurs sources (fedora, flathub... sont disponible, choisir la meme source pour les deux paquets)
flatpak install org.virt_manager.virt-manager
flatpak install org.virt_manager.virt_manager.Extension.Qemu

# parfois flatpak n'arrive pas a savoir si on est en branche stable ou master sur virt-manager (et cela provoque l'erreur "libvirt.libvirtError: binary '/app/bin/virtqemud' does not exist in $PATH: No such file or directory" lorsqu'on veut créer la connection utilisateur). Alors il faut faire :
flatpak run org.virt_manager.virt-manager//stable


echo "Ce script va installer les logiciels CLI suivants (dans toolbox, sans faire de layer OSTREE):
- groff : processeur de texte en ligne de commande
- htop : moniteur système avancé, léger en en CLI
- lynx : nvigateur web en cli
- midnight commander (mc) : gestionnaire de fichier en terminal
- pandoc : manipulation de formats de documents et textes, avec batches
- imagemagick : manipulation d'image en batch ligne de commande
N'installer que des logiciels en ligne de commande. Toolbox peut tout à faite exécuter des logiciels graphiques, mais qui vont propager leurs fichiers de config dans home. A éviter (sauf si ces logiciels graphiques sont voués à être executé de façon pérenne. Eviter des logiciels GTK dans ce cas, toujours pour ne pas compléxifier le répertoire home. Mais on peut installer une toolbox dans une machine virtuelle Fedora expres pour bidouiller)
"
toolbox create
toolbox enter
sudo dnf install groff htop lynx mc pandoc
# Eventuellement :
# sudo dnf ImageMagick
exit






- Drawing : dessin et retouche basique (comme Paint)
- Gimp
- Foliate (lecteur ebook format epub. Pour les pdf il y a evince/visionneur de documents qui est installé par defaut)
- Xournal++ : modification de fichiers pdf
- Pdf arranger : fusion, suppression, réorganisation de pdf
- Qpdf : fusion, suppression, réorganisation, extraction de pages de pdf (en ligne de commande)
- Lollypop : lecteur de musique épuré et ergonomique
- Celluloid : lecteur utilisant MPV, plus efficace que Gnome Video
- Kodi : lecteur multimedia
- Handbrake : conversion video / audio
- yt-dlp (téléchargement de vidéos depuis plateformes vidéo en ligne)
- mtpaint : ressemble à paint.net
"
echo "========================================================="
sleep 5
