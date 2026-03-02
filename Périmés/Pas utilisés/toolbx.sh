# Script de création de la Toolbx pour les outils qui y sont disponibles, si on veut utiliser ce moyen pour installer les outils CLI. Inconvenient : n'est pas dispo dans bazzite et autres immutables ublue. Préférer brew.

# Nommer la Toolbox
TBX_NAME="CLI_tools"


# Lister les applications CLI
APPS_TOOLBOX=(
    lm_sensors
    dialog      # outils pratique pour créer des boites de dialogue dans les scripts
    duf         # analyse  espace disque
    powertop    # gestion d'énèrgie https://commandmasters.com/commands/powertop-linux/
    stow        # Gestionnaire de dotfiles (gestion automatisée de liens symboliques vers ~/.config/  -> permet de faire un repo github rationnel) 
    stress-ng   # outil de stress CPU : stress-ng --cpu 0 --cpu-method matrixprod -v
    python313   # prend 45 Mo. Préférer à la version 315 qui prend 130 Mo
    s-tui       # Interface graphique CLI pour monitorer fréquence/température. Prend 49 Mo, dont la majorité en commun avec python 313
    htop        # gestionnaire de processus
    btop        # gestionnaire de processus, plus graphique
    mc          # gestionnaire de fichiers. Prend 45 Mo, mais la majeur parti est commune aux dépendances de python313
    just
)

# Mise en place de la Toolbox
if ! toolbox list | grep -q "$TBX_NAME"; then
    echo "🏗️  Création de la Toolbx : $TBX_NAME..."
    toolbox create -c "$TBX_NAME" -y
    echo "📦 Pré-installation des utilitaires essentiels dans la Toolbx..."
    toolbox run -c "$TBX_NAME" sudo dnf install -y "${APPS_TOOLBOX[@]}"
else
    echo "✅ Toolbx '$TBX_NAME' déjà opérationnelle."
fi


# Création des wrapper dans .local/bin

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

echo "🛠️ Création des wrappers Toolbox dans $BIN_DIR..."

for app in "${APPS_TOOLBOX[@]}"; do
    WRAPPER_PATH="$BIN_DIR/$app"
    
    # On crée le mini-script wrapper
    cat <<EOF > "$WRAPPER_PATH"
#!/usr/bin/env bash
exec toolbox run -c "$TBX_NAME" "/usr/bin/$app" "\$@"
EOF

    # On le rend exécutable
    chmod +x "$WRAPPER_PATH"
    echo "  ✅ Wrapper créé pour : $app"
done

echo "🚀 Terminé ! Tu peux maintenant taper '${APPS_TOOLBOX[0]}' directement dans ton terminal hôte."
