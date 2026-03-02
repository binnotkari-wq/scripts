# Installation de mdcat. Préférer avec brew.

# Mdcat
if ! command -v mdcat &> /dev/null; then
    echo "  -> Installation de Mdcat..."
    # On utilise un dossier temporaire pour ne prendre QUE le binaire et pas les docs/licences
    TEMP_DIR=$(mktemp -d)
    curl -L "https://github.com/swsnr/mdcat/releases/download/mdcat-2.7.1/mdcat-2.7.1-x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C "$TEMP_DIR"
    mv "$TEMP_DIR"/mdcat-*/mdcat "$BIN_DIR/"
    rm -rf "$TEMP_DIR"
    chmod +x "$BIN_DIR/mdcat"
fi
