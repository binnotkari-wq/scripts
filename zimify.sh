#!/bin/bash

# on veut ajouter un contenu (qui se trouve dans le fichier 00_entête.txt) au début de chaque fichiers
# textes d'un lot (ici, il s'agissait de fichiers texte résultant d'une conversion de l'export .html de
# NoteKeep (voir "Convertire HTML en TXT.md"). Cela permettra leur reconnaissance en tant que page dans Zim.
# Mais il faut au préalable nettoyer les noms de fichiers.


# préparation : création du dossier de sortie
mkdir -p txt_entete_zim

# instruction : "file" est le nom de chaque fichier txt existant dans le répertoire où on place le script,
# et qu'on veut renommer de façon valide pour Zim
for file in *.txt; do

# suppression des espaces dans les noms de fichier, et remplacement par _ (sinon, seront ignorés par Zim)
mv -- "$file" "${file// /_}"

done



# instruction : "file" est le nom de chaque fichier txt existant (et renommé, à présent) dans 
# le répertoire où on place le script, et qu'on veut faire reconnaitre par Zim en ajoutant l'entête-type de Zim.

for file in *.txt; do
# création d'un fichier vide dans le répertoire de sortie, portant le même nom que les fichiers originaux
touch "txt_entete_zim/${file%.txt}.txt"

# fusion du contenu de l'entête, avec le contenu de chaque fichier. Cette fusion est redirigée
# vers chaque fichier de sortie portant le même nom.
cat "00_entete.txt" "${file%.txt}.txt" > "txt_entete_zim/${file%.txt}.txt"

done
