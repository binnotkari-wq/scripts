#!/bin/bash

# Nom du dossier racine (modifiable)
ROOT_DIR="${1:-$HOME/Mes-Donnees}"

echo "Création de l'arborescence dans : $ROOT_DIR"

# Fonction pour créer un dossier et afficher une confirmation
mkdir_if_not_exists () {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Créé : $1"
    else
        echo "Existant : $1"
    fi
}

# Création des dossiers principaux
mkdir_if_not_exists "$ROOT_DIR/01_Souvenirs/Photos"
mkdir_if_not_exists "$ROOT_DIR/01_Souvenirs/Vidéos"
mkdir_if_not_exists "$ROOT_DIR/01_Souvenirs/Lettres"
mkdir_if_not_exists "$ROOT_DIR/01_Souvenirs/Enregistrements_Audio"

mkdir_if_not_exists "$ROOT_DIR/02_Documents_Importants/Administratif"
mkdir_if_not_exists "$ROOT_DIR/02_Documents_Importants/Identité_Numérique"
mkdir_if_not_exists "$ROOT_DIR/02_Documents_Importants/Contrats"

mkdir_if_not_exists "$ROOT_DIR/03_Ressources_Externes/Livres"
mkdir_if_not_exists "$ROOT_DIR/03_Ressources_Externes/Musique"
mkdir_if_not_exists "$ROOT_DIR/03_Ressources_Externes/Vidéos"
mkdir_if_not_exists "$ROOT_DIR/03_Ressources_Externes/Tutoriels"

mkdir_if_not_exists "$ROOT_DIR/04_Archives/Projets_Termines"
mkdir_if_not_exists "$ROOT_DIR/04_Archives/Démarches_Accomplies"
mkdir_if_not_exists "$ROOT_DIR/04_Archives/Anciens_Documents"

mkdir_if_not_exists "$ROOT_DIR/05_En_Cours/Projets_Actuels"
mkdir_if_not_exists "$ROOT_DIR/05_En_Cours/Démarches_En_Cours"
mkdir_if_not_exists "$ROOT_DIR/05_En_Cours/Fiches_A_Travailler"
mkdir_if_not_exists "$ROOT_DIR/05_En_Cours/Notes_Rapides"

mkdir_if_not_exists "$ROOT_DIR/99_Technique/AppImages"
mkdir_if_not_exists "$ROOT_DIR/99_Technique/Scripts"
mkdir_if_not_exists "$ROOT_DIR/99_Technique/Installations"

echo "Arborescence créée avec succès !"

