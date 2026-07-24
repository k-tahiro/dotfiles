#!/bin/bash
set -euo pipefail

if command -v mise &> /dev/null; then
    echo "mise is already installed. Skipping."
    exit 0
fi

echo "Installing mise via official installer..."
curl -fsSL https://mise.run | sh

MISE_BIN="${HOME}/.local/bin"
MISE_SHIMS="${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims"
export PATH="$MISE_BIN:$MISE_SHIMS:$PATH"

if ! command -v mise &> /dev/null; then
    echo "Error: mise installation failed." >&2
    exit 1
fi

echo "mise $(mise --version) installed."
