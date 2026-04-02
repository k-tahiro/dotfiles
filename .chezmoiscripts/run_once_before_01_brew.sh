#!/bin/bash
set -euo pipefail

if command -v brew &> /dev/null; then
    echo "Homebrew is already installed. Skipping."
    exit 0
fi

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon Mac / Linux の場合、brew を PATH に追加
if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ "$(uname -s)" == "Linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

echo "Homebrew installation complete."
