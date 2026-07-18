#!/usr/bin/env bash

executer_logique() {
  definir_variables

  if [[ ! -f "$USER_HOME/.git-credentials" ]]; then
    setup_git_credentials
  else
    echo "Authentification git déjà enregistrée"
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
  MY_GIT_DIR="$USER_HOME/Git"
  echo "🛡️ Mise en place de Git pour $USER_NAME"
  mkdir -p "$MY_GIT_DIR"
}

setup_git_credentials() {
  echo "🔑 Configuration de l'authentification Git..."
  git config --global user.name "binnotkari-wq"
  git config --global user.email "benoit.dorczynski@gmail.com"
  git config --global credential.helper store

  # Sécurité pour éviter les erreurs de "dossier non sûr" sur NixOS
  git config --global --add safe.directory "$USER_HOME/Git/*"

  git config --global init.defaultBranch main

  if [ -n "$GITHUB_TOKEN" ]; then
      echo "https://binnotkari-wq:$GITHUB_TOKEN@github.com" > "$USER_HOME/.git-credentials"
      chmod 600 "$USER_HOME/.git-credentials"
      echo "✅ Token GitHub pré-enregistré."
  fi
}

definir_repos () {
REPOS=(
  "archives"
  "atomic-install_script"
  "home-manager"
  "nixos-dotfiles"
  "nixos-install_script"
  "pastebin"
  "scripts"
  "user-deploy"
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
      cd "$TARGET" || continue

      BRANCH=$(git rev-parse --abbrev-ref HEAD)

      # On récupère l'état distant sans fusionner
      git fetch origin

      # S'il y a des changements locaux, on les commit
      if [[ -n $(git status --porcelain) ]]; then
        git add .
        git commit -m "Auto-sync [$HOST] : $(date '+%Y-%m-%d %H:%M:%S')"
      fi

      # On rebase sur la version distante puis on pousse
      git pull --rebase origin "$BRANCH"
      git push origin "$BRANCH"
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
