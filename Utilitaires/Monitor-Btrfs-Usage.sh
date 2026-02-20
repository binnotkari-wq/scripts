#!/usr/bin/env bash

echo "Surveillance de l'occupation exclusive de / (root)..."
echo "Temps     | Occupation (Mo)"
echo "---------------------------"

while true; do
  # Récupère l'ID du sous-volume monté sur /
  SUBVOL_ID=$(sudo btrfs subvolume show / | grep "Subvolume ID" | awk '{print $3}')

  # Récupère la taille exclusive en octets
  USAGE=$(sudo btrfs qgroup show --raw / | grep "0/$SUBVOL_ID" | awk '{print $3}')

  # Calcul simple en Mo sans utiliser 'bc' (division entière via bash)
  # 1048576 = 1024 * 1024
  USAGE_MB=$(( USAGE / 1048576 ))

  echo "$(date +%H:%M:%S)  -> $USAGE_MB Mo"
  sleep 60
done
