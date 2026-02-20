#!/bin/bash

echo "========================================================="
# Message de présentation
echo "Téléchargement de l'Appimage de Kiwix dans $HOME/opt/ et création du raccourci (avec récupération du fichier d'image pour l'icone)"

sleep 2

# création du dossier
mkdir $HOME/opt/Kiwix

# téléchargement dans le dossier
cd $HOME/opt/Kiwix
wget https://download.kiwix.org/release/kiwix-desktop/kiwix-desktop_x86_64.appimage

# rendre executable
chmod +x kiwix-desktop_x86_64.appimage

# récupération du logo icone
wget https://upload.wikimedia.org/wikipedia/commons/c/c4/Logo-kiwix-vertical.svg

# création du raccourci :

# Dossier cible
desktop_dir="$HOME/.local/share/applications"
mkdir -p "$desktop_dir"

# Chemin complet du fichier .desktop
desktop_file="$desktop_dir/Kiwix.desktop"

# Contenu du fichier .desktop
cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Kiwix
Comment=
Exec=$HOME/opt/Kiwix/kiwix-desktop_x86_64.appimage
Icon=$HOME/opt/Kiwix/Logo-kiwix-vertical.svg
Terminal=false
Type=Application
Categories=Education;
EOF

# Rendre exécutable
chmod +x "$desktop_file"

# Rafraîchir la base des menus (si l'outil est installé)
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$desktop_dir"
else
    echo "⚠️  'update-desktop-database' n'est pas installé. Ce n'est pas bloquant, mais l'entrée peut apparaître avec un peu de retard."
fi

echo "✅ Raccourci 'Kiwix' créé avec succès dans $desktop_dir"
