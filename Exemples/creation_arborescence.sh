#!/bin/bash

DOCROOT="Documentation_Debian_Offline"

mkdir -p "$DOCROOT"/{01_Commandes_de_base,02_Système,03_Préférences_et_personnalisation,04_Matériel_et_périphériques,05_Réseau,06_Paquets_et_logiciels,07_Scripts_et_automatisation,08_Sécurité_et_sauvegarde,09_Références_externalisées}

touch "$DOCROOT"/00_Index.md
touch "$DOCROOT"/LICENSE.md

echo "Structure de documentation Debian initialisée dans ./$DOCROOT/"

