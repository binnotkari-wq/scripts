#!/usr/bin/env bash

executer_logique() {
  definir_variables

  if [[ ! -f "$USER_HOME/.git-credentials" ]]; then
    setup_git_credentials
  else
    echo "Authentification git déjà enregistrée"
  fi

  if [[ ! -f ""$SERVICE_FILE"" ]]; then
  setup_sync_service
  else
    echo "Service de synchronisation déjà installé"
  fi

  definir_repos
  synchroniser_repos

  echo "✨ Git en place et synchronisation configurée."
}


#====================================
# FONCTIONS
#====================================


definir_variables() {
  # 0. Détection de l'utilisateur et du HOME (robuste pour NixOS/Silverblue)
  USER_NAME=$(whoami)
  USER_HOME=$HOME
  MY_GIT_DIR="$USER_HOME/Mes-Donnees/Git"
  SERVICE_DIR="$USER_HOME/.config/systemd/user"
  SERVICE_FILE="$SERVICE_DIR/git-sync-on-shutdown.service"
  echo "🛡️ Mise en place de Git pour $USER_NAME"
  mkdir -p $MY_GIT_DIR
}

setup_git_credentials() {
  echo "🔑 Configuration de l'authentification Git..."
  git config --global user.name "binnotkari-wq"
  git config --global user.email "benoit.dorczynski@gmail.com"
  git config --global credential.helper store

  # Sécurité pour éviter les erreurs de "dossier non sûr" sur NixOS
  git config --global --add safe.directory "$USER_HOME/Mes-Donnees/Git/*"

  git config --global init.defaultBranch main

  if [ -n "$GITHUB_TOKEN" ]; then
      echo "https://binnotkari-wq:$GITHUB_TOKEN@github.com" > "$USER_HOME/.git-credentials"
      chmod 600 "$USER_HOME/.git-credentials"
      echo "✅ Token GitHub pré-enregistré."
  fi
}

setup_sync_service() {
  echo "⚙️ Configuration du service systemd..."
  mkdir -p "$SERVICE_DIR"

  # On trouve le chemin de 'true' de façon dynamique pour NixOS/Silverblue
  TRUE_PATH=$(command -v true)

  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Synchronisation Git des dépôts à la fermeture de session
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$TRUE_PATH
# On injecte le chemin complet calculé pour éviter les problèmes de variables
ExecStop=$USER_HOME/Mes-Donnees/Git/user-deploy/modules/git-sync.sh

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable git-sync-on-shutdown.service

  # Linger est crucial pour que les services --user tournent au shutdown sur Silverblue
  loginctl enable-linger "$USER_NAME"
  echo "✅ Service systemd configuré."
}

definir_repos () {
REPOS=(
  "archives"
  "atomic-install_script"
  "home-manager"
  "info_doc"
  "nixos-dotfiles"
  "nixos-install_script"
  "pastebin"
  "scripts"
  "user-deploy"
  "user-dotfiles"
  "mini-projects"
  )
}

synchroniser_repos() {
HOST=$(hostname)
echo "--- Début de la synchronisation sur [$HOST] : $(date) ---"

for repo in "${REPOS[@]}"; do
    TARGET="$MY_GIT_DIR/$repo"
    if [ -d "$TARGET" ]; then
        echo "🔄 $repo : Mise à jour..."
        # Utilisation de -C pour être indépendant du dossier actuel
        git -C "$TARGET" pull
        cd "$TARGET" || continue
        git fetch origin

        if [[ -n $(git status --porcelain) ]]; then
            git add .
            # Commit avec le nom de la machine
            git commit -m "Auto-sync [$HOST] : $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        git push origin $(git rev-parse --abbrev-ref HEAD) 2>/dev/null
        git pull --rebase origin $(git rev-parse --abbrev-ref HEAD)
    else
        echo "🚀 $repo : Clonage..."
        git clone "https://github.com/binnotkari-wq/$repo.git" "$TARGET"
    fi
done
}


# =============================================================================
# EXECUTION
# =============================================================================

executer_logique "$@"
