#!/bin/bash

echo "========================================================="
# Message de présentation
echo "Ce script va installer les logiciels GTK suivants :
- Drawing : dessin et retouche basique (comme Paint)
- Gimp
- Zim : prise de note, export en formats multiples (dont .Md)
- Apostrophe (lecteur / editeur markdown qui prend en charge les mises en formes markdown avancées).
- Foliate (lecteur ebook format epub. Pour les pdf il y a evince/visionneur de documents qui est installé par defaut)
- Xournal++ : modification de fichiers pdf
- Pdf arranger : fusion, suppression, réorganisation de pdf
- Qpdf : fusion, suppression, réorganisation, extraction de pages de pdf (en ligne de commande)
- Lollypop : lecteur de musique épuré et ergonomique
- Celluloid : lecteur utilisant MPV, plus efficace que Gnome Video
- Kodi : lecteur multimedia
- Handbrake : conversion video / audio
- yt-dlp (téléchargement de vidéos depuis plateformes vidéo en ligne)
- Gnome-boxes (Machines) + modules de virtualisation et partage de presse-papier
- Secrets : trousseau de login / MDP (gère les bases de données keepass)
- Htop : moniteur système avancé, léger en en CLI
- Meld : comparaison de fichiers et répertoire exactement comme Winmerge
- gnome-shell-extensions : sans doute installé par défaut.... pour personaliser l'interface de gnome avec des extensions (elle seront à installé manuellement, pas d'install automatisée disponible). 
- mtpaint : ressemble à paint.net
- imagemagick : manipulation d'image en batch ligne de commande
- groff : processeur de texte en ligne de commande
- midnight commander : mc mc-data (gestionnaire de fichier en terminal)
- documentation : debian-faq-fr debian-handbook debian-history debian-refcard debian-reference-common debian-reference-fr manpages-fr apt-doc dochelp openshot-qt-doc imagemagick-doc gimp-help-fr ffmpeg-doc gimp-help-fr linux-doc mame-doc parted-doc
- Warzone 2100 : STR natif linux
- curl : un prérequis à Steam (qui sera à installer depuis le .deb officiel du site internet de steam)

Les logiciels suivants seront supprimés : Rythmbox, Musique.
"
echo "========================================================="
sleep 5

sudo apt-get update
sudo apt-get install drawing gimp zim apostrophe foliate xournalpp pdfarranger qpdf lollypop celluloid kodi handbrake yt-dlp gnome-boxes libvirt-clients spice-vdagent secrets htop meld gnome-shell-extensions mtpaint imagemagick groff mc mc-data debian-faq-fr debian-handbook debian-history debian-refcard debian-reference-common debian-reference-fr manpages-fr apt-doc dochelp openshot-qt-doc imagemagick-doc gimp-help-fr ffmpeg-doc gimp-help-fr linux-doc mame-doc parted-doc warzone2100 curl
sudo apt-get remove --purge  rhythmbox gnome-music
sudo apt-get autoremove
