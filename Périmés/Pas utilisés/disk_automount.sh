#!/usr/bin/env bash

BIN_DIR="$HOME/.local/bin"
SERVICE_DIR="$HOME/.config/systemd/user"
SCRIPT_PATH="$BIN_DIR/mount-extra-disks.sh"
SERVICE_PATH="$SERVICE_DIR/mount-extra-disks.service"

mkdir -p "$BIN_DIR" "$SERVICE_DIR"

# Création du script avec une détection de disque système plus fiable
cat << 'EOF' > "$SCRIPT_PATH"
#!/usr/bin/env bash

username=$(whoami)

# 1. Détecter le disque qui contient la partition racine (/)
# On cherche le nom du parent du point de montage /
system_disk=$(lsblk -no PKNAME $(findmnt -nvo SOURCE /) | head -n1)

# Si c'est vide (cas complexes), on essaie une alternative
if [ -z "$system_disk" ]; then
    system_disk=$(lsblk -lno NAME,MOUNTPOINT | grep -E ' /$' | awk '{print $1}' | sed 's/[0-9]*//g')
fi

echo "Disque système ignoré : $system_disk"

# 2. Boucle sur les disques, en ignorant le disque système
# On filtre les disques (type 'disk') et on exclut le disque système
for dev in $(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print $1}' | grep -v "$system_disk"); do
    
    # 3. Boucle sur les partitions du disque secondaire
    for part in $(lsblk -ln /dev/$dev -o NAME,TYPE | awk '$2=="part"{print $1}'); do
        device="/dev/$part"
        
        # Récupérer le label
        label=$(lsblk -no LABEL "$device")
        [ -z "$label" ] && label="$part"
        
        mount_point="/run/media/${username}/${label}"

        # Vérifier si déjà monté (via le device ou le point de montage)
        if ! mountpoint -q "$mount_point" && ! mount | grep -q "$device"; then
            echo "Tentative de montage : $device sur $mount_point"
            mkdir -p "$mount_point"
            
            # Utilisation de udisksctl (universel et sans sudo)
            udisksctl mount -b "$device" --no-user-interaction 2>/dev/null
            
            # Fallback mount si udisksctl échoue
            if [ $? -ne 0 ]; then
                mount -o users,nofail,noatime "$device" "$mount_point" 2>/dev/null
                chown -R "$username":users "$mount_point" 2>/dev/null
            fi
        else
            echo "Déjà monté ou occupé : $device"
        fi
    done
done
EOF

chmod +x "$SCRIPT_PATH"

# Création du service Systemd
cat << EOF > "$SERVICE_PATH"
[Unit]
Description=Monte tous les disques internes secondaires
After=default.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=true

[Install]
WantedBy=default.target
EOF

# Activation
systemctl --user daemon-reload
systemctl --user enable mount-extra-disks.service
systemctl --user start mount-extra-disks.service

echo "---"
echo "Installation terminée. Teste maintenant en tapant : mount-extra-disks.sh"
