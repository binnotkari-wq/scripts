#!/bin/bash

echo "========================================================="
# Message de présentation
echo "Téléchargement de l'Appimage de Openshot dans $HOME/opt/ et création du raccourci (avec récupération du fichier d'image pour l'icone)"

sleep 2

# création du dossier
mkdir $HOME/opt/Openshot

# téléchargement dans le dossier
cd $HOME/opt/Openshot
wget https://github.com/OpenShot/openshot-qt/releases/download/v3.3.0/OpenShot-v3.3.0-x86_64.AppImage

# rendre executable
chmod +x OpenShot-v3.3.0-x86_64.AppImage

# récupération du logo icone
wget https://raw.githubusercontent.com/OpenShot/openshot-qt/4de6e593c498e70e321679b444e07e2b506ecbd0/xdg/openshot-qt.svg

# création du raccourci :

# Dossier cible
desktop_dir="$HOME/.local/share/applications"
mkdir -p "$desktop_dir"

# Chemin complet du fichier .desktop
desktop_file="$desktop_dir/Openshot.desktop"

# Contenu du fichier .desktop
cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Openshot
Comment=
Exec=$HOME/opt/Openshot/OpenShot-v3.3.0-x86_64.AppImage
Icon=$HOME/opt/Openshot/openshot-qt.svg
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

echo "✅ Raccourci 'Openshot' créé avec succès dans $desktop_dir"
