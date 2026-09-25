#!/usr/bin/env bash

set -e

# Configuration
OLD_EMAIL="$USER.dorczynski@gmail.com"
NEW_TEXT="VOTRE_EMAIL"
GITHUB_USER="binnotkari-wq"

REPOS=(
  "archives"
  "atomic-settings"
  "mini-projects"
  "nixos-dotfiles"
  "offline-essentials"
  "post-install"
  "scripts"
  "silverblue_bootc"
)

# Vérification de la présence de git-filter-repo
if ! command -v git-filter-repo &> /dev/null; then
  echo "❌ Error: git-filter-repo n'est pas installé."
  exit 1
fi

PARENT_DIR=$(pwd)

echo "🚀 Début du nettoyage massif pour $GITHUB_USER..."
echo "------------------------------------------------"

for repo in "${REPOS[@]}"; do
  REPO_PATH="$PARENT_DIR/$repo"

  if [ ! -d "$REPO_PATH" ]; then
    echo "⚠️  [Ignoré] Le dossier '$repo' n'existe pas dans $PARENT_DIR"
    continue
  fi

  echo ""
  echo "📂 Traitement du dépôt : $repo"
  cd "$REPO_PATH"

  # 1. Vérification que c'est bien un dépôt Git
  if [ ! -d ".git" ]; then
    echo "⚠️  [Ignoré] '$repo' n'est pas un dépôt Git."
    cd "$PARENT_DIR"
    continue
  fi

  # 2. Remplacement du texte dans l'historique des fichiers
  # Et mise à jour éventuelle des métadonnées des commits (author/committer)
  echo "  🧹 Nettoyage de l'historique..."
  git-filter-repo --force \
    --replace-text <(echo "$OLD_EMAIL==>$NEW_TEXT") \
    --email-callback "return email.replace(b'$OLD_EMAIL', b'$NEW_TEXT')"

  # 3. Ré-association du remote origin (git-filter-repo le supprime par sécurité)
  REMOTE_URL="https://github.com/$GITHUB_USER/$repo.git"
  echo "  🔗 Configuration du remote origin ($REMOTE_URL)..."
  git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"

  # 4. Push forcé sur GitHub
  echo "  ⬆️  Push forcé sur GitHub..."
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  git push origin "$BRANCH" --force

  echo "  ✅ Dépôt $repo nettoyé et mis à jour !"
  cd "$PARENT_DIR"
done

echo ""
echo "------------------------------------------------"
echo "🎉 Opération terminée sur tous les dépôts !"
