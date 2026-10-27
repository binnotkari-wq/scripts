#!/usr/bin/env bash
# 27/10/2026 script rapide d'après https://linuxvox.com/blog/clean-up-disk-space-ubuntu/

set -euo pipefail

sudo apt update && \
sudo apt clean && \
sudo apt autoclean && \
sudo apt autoremove && \
sudo apt autoremove --purge && \
flatpak uninstall --unused && \
sudo rm -rf /var/tmp/flatpak-cache-*
