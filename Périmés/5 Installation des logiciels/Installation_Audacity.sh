#!/bin/bash

echo "========================================================="
# Message de présentation
echo "Téléchargement de l'Appimage de Audacity dans $HOME/opt/ et création du raccourci (avec récupération du fichier d'image pour l'icone)"

sleep 2

# création du dossier
mkdir $HOME/opt/Audacity

# téléchargement dans le dossier
cd $HOME/opt/Audacity
wget https://github.com/audacity/audacity/releases/download/Audacity-3.7.4/audacity-linux-3.7.4-x64-22.04.AppImage

# rendre executable
chmod +x audacity-linux-3.7.4-x64-22.04.AppImage

# récupération du logo icone
wget https://upload.wikimedia.org/wikipedia/commons/f/fd/Audacity.png

# création du raccourci :

# Dossier cible
desktop_dir="$HOME/.local/share/applications"
mkdir -p "$desktop_dir"

# Chemin complet du fichier .desktop
desktop_file="$desktop_dir/Audacity.desktop"

# Contenu du fichier .desktop
cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Audacity
Comment=
Exec=$HOME/opt/Audacity/audacity-linux-3.7.4-x64-22.04.AppImage
Icon=$HOME/opt/Audacity/Audacity.png
Terminal=false
Type=Application
Categories=AudioVideo;
EOF

# Rendre exécutable
chmod +x "$desktop_file"

# Rafraîchir la base des menus (si l'outil est installé)
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$desktop_dir"
else
    echo "⚠️  'update-desktop-database' n'est pas installé. Ce n'est pas bloquant, mais l'entrée peut apparaître avec un peu de retard."
fi

echo "✅ Raccourci 'Audacity' créé avec succès dans $desktop_dir"
