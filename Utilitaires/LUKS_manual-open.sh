#!/usr/bin/env bash
# ouvrir ponctuellement et manuellement un volume LUKS
# par exemple si on veut intervenir dessus depuis un live usb ou un nouvel OS

set -euo pipefail

lsblk -o NAME,FSTYPE,UUID,MOUNTPOINT

echo "indiquer l'UUID du volume LUKS à ouvrir :"
read -r CHOICE

sudo cryptsetup luksOpen /dev/disk/by-uuid/$CHOICE old_btrfs
sudo mount -o subvolid=5 /dev/mapper/old_btrfs /mnt
sudo btrfs subvolume list /mnt
cd /mnt

echo "Volume ouvert."
echo "pour fermer proprement :"
echo "sudo umount /mnt"
echo "sudo cryptsetup luksClose /dev/disk/by-uuid/$CHOICE"
