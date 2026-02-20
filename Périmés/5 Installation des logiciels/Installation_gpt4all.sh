#!/bin/bash

echo "========================================================="
# Message de présentation
echo "Téléchargement de l'installateur .run de GPT4All dans $HOME/Téléchargements/ et création du raccourci (avec récupération du fichier d'image pour l'icone)"

sleep 2

# création du dossier
mkdir $HOME/opt/gpt4all

# téléchargement dans le dossier
cd $HOME/Téléchargements
wget https://gpt4all.io/installers/gpt4all-installer-linux.run

# rendre executable
chmod +x gpt4all-installer-linux.run

# exéctuer l'installeur
./gpt4all-installer-linux.run

# création du raccourci :

# Dossier cible
desktop_dir="$HOME/.local/share/applications"
mkdir -p "$desktop_dir"

# Chemin complet du fichier .desktop
desktop_file="$desktop_dir/GPT4All.desktop"

# Contenu du fichier .desktop
cat > "$desktop_file" << EOF
[Desktop Entry]
Name=GPT4All
Comment=
Exec="/home/benoit/opt/gpt4all/bin/chat"
Icon=/home/benoit/opt/gpt4all/gpt4all-48.png
Terminal=false
Type=Application
Categories=Utility;
EOF

# Rendre exécutable
chmod +x "$desktop_file"

# Rafraîchir la base des menus (si l'outil est installé)
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$desktop_dir"
else
    echo "⚠️  'update-desktop-database' n'est pas installé. Ce n'est pas bloquant, mais l'entrée peut apparaître avec un peu de retard."
fi

echo "✅ Raccourci 'GPT4All' créé avec succès dans $desktop_dir"
