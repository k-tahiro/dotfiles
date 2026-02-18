#!/bin/bash
set -euo pipefail

if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

echo "Updating for Homebrew packages..."
brew upgrade
