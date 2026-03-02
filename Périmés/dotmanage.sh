#!/usr/bin/env bash

# --- Configuration ---
DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) # cela renvoi le chemin à partir duquel le script est exécuté
# Liste unique des applications à gérer. Pour info, PBE = QownNotes et applications = les raccourcis dans ~/.local/share
APPS=("bash" "btop" "htop" "foot" "zellij" "kate" "mc" "pyradio" "PBE" "applications" "celluloid" "fragments" "kiwix-desktop" "shortcuts")

# Fichier de sauvegarde Gnome dans ton repo
GNOME_CONF="$DOTFILES_DIR/gnome/settings.dconf"
mkdir -p "$DOTFILES_DIR/gnome"

echo "=========================================="
echo "   Gestionnaire de Dotfiles (Stow + Gnome)"
echo "=========================================="
echo "1) [MIGRER]   Local -> Depot (Sauvegarde)"
echo "2) [DÉPLOYER] Depot -> Local (Installation)"
echo "3) [QUITTER]"
read -p "Votre choix [1-3] : " CHOICE

case $CHOICE in
    1)
        echo "--- 📸 Capture des réglages Gnome ---"
        # On capture : thèmes, polices, extensions et apps favorites
        {
          dconf dump /
          # dconf dump /org/gnome/desktop/interface/
          # dconf dump /org/gnome/shell/extensions/
          # dconf dump /org/gnome/shell/favorite-apps
          # dconf dump /org/gnome/settings-daemon/plugins/media-keys/
          # dconf dump /org/gnome/desktop/background/      # Fond d'écran (Wallpaper)
          # dconf dump /org/gnome/desktop/screensaver/     # Fond d'écran de l'écran de verrouillage
          # dconf dump /org/gnome/desktop/interface/color-scheme # Mode Sombre / Clair
          # dconf dump /org/gnome/desktop/interface/accent-color # Couleur d'accentuation (GNOME 47+)
        } > "$GNOME_CONF"
        echo "[OK] Gnome sauvegardé."
        
        echo "--- 📦 Migration vers le dépôt ---"
        for APP in "${APPS[@]}"; do
            if [ -d "$HOME/.config/$APP" ] && [ ! -L "$HOME/.config/$APP" ]; then
                echo "Déplacement de $APP..."
                mkdir -p "$DOTFILES_DIR/$APP/.config"
                mv "$HOME/.config/$APP" "$DOTFILES_DIR/$APP/.config/"
                stow -v -t "$HOME" "$APP"
            else
                echo "✅ $APP est déjà géré ou absent."
            fi
        done

    
    2)   
        echo "--- 🔗 Liaison des fichiers (Stow) ---"
        for APP in "${APPS[@]}"; do
            if [ -d "$APP" ]; then
                stow -v -t "$HOME" "$APP"
            fi
        done

        echo "--- 🎨 Application des réglages Gnome ---"
        if [ -f "$GNOME_CONF" ]; then
            dconf load /org/gnome/ < "$GNOME_CONF"
            echo "[OK] Gnome mis à jour."
        fi
        ;;

    *)
        echo "Au revoir !"
        exit 0
        ;;
esac

echo "=========================================="
echo "Opération terminée avec succès."
