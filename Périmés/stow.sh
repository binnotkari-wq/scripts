#!/usr/bin/env bash




# 01/03/2026 A faire : récupérer les preferences des applis flatpak


# --- Configuration ---
# On s'assure que DOTFILES_DIR pointe bien vers le dossier où sont les dossiers d'apps
DOTFILES_DIR="$HOME/Mes-Donnees/Git/user-dotfiles"

APPS=("bash" "btop" "htop" "foot" "zellij" "kate" "mc" "pyradio" "PBE" "applications" "celluloid" "fragments" "kiwix-desktop" "shortcuts")

echo "=========================================="
echo "    Importation de Dotfiles (Stow + Gnome)"
echo "=========================================="

# 1. Préparation spécifique pour Bash
# Stow échouera si un vrai fichier .bashrc existe déjà
if [ -f ~/.bashrc ] && [ ! -L ~/.bashrc ]; then
    echo "⚠️  Sauvegarde du .bashrc existant en .bashrc.bak"
    mv ~/.bashrc ~/.bashrc.bak
fi

# 2. Liaison des fichiers (Stow)
echo "--- 🔗 Liaison des fichiers (Stow) ---"
cd "$DOTFILES_DIR"

for APP in "${APPS[@]}"; do
    if [ -d "$APP" ]; then
        # -R : récursif, -v : verbeux, -t : cible
        stow -R -v -t "$HOME" "$APP"
    else
        echo "⏭️  Saut de $APP (dossier non trouvé dans $DOTFILES_DIR)"
    fi
done

# 3. Application des réglages Gnome
# On utilise le chemin relatif au repo pour le fichier dconf
GNOME_CONF="$DOTFILES_DIR/gnome/settings.dconf"

echo "--- 🎨 Application des réglages Gnome ---"
if [ -f "$GNOME_CONF" ]; then
    dconf load /org/gnome/ < "$GNOME_CONF"
    echo "[OK] Gnome mis à jour."
else
    echo "ℹ️  Aucun fichier de config Gnome trouvé, on passe."
fi

echo "=========================================="
echo "Opération terminée avec succès."
