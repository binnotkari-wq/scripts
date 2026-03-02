# Installation de Zellij. Préférer avec brew.

# Zellij (Version MUSL - Excellente pour la portabilité)
if ! command -v zellij &> /dev/null; then
    echo "  -> Installation de Zellij..."
    # Zellij est souvent un binaire seul dans le .tar.gz, pas de strip-components ici
    curl -L "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C "$BIN_DIR"
    chmod +x "$BIN_DIR/zellij"
fi
