#!/bin/bash

BINARY="hypr-dock-autohide"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "→ Parando daemon..."
"$INSTALL_DIR/$BINARY" -stop 2>/dev/null || true

echo "→ Compilando..."
cd "$SCRIPT_DIR/main" || { echo "✗ Diretório 'main' não encontrado"; exit 1; }

if ! go build -o "$SCRIPT_DIR/$BINARY" .; then
    echo "✗ Falha na compilação"
    exit 1
fi

echo "✓ Compilado"

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/$BINARY" "$INSTALL_DIR/$BINARY" || { echo "✗ Falha ao instalar binário"; exit 1; }
chmod +x "$INSTALL_DIR/$BINARY"
echo "✓ Instalado em $INSTALL_DIR/$BINARY"

echo "→ Iniciando daemon..."
"$INSTALL_DIR/$BINARY" &
echo "✓ Pronto!"