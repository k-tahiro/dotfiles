#!/bin/bash
set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "Error: mise is not installed. Please install mise first."
    exit 1
fi

mise self-update -y

# bootstrap は sudo (apt/brew 等のシステムパッケージ) を必要とする。
# sudo が無い / 非対話で使えない環境ではスキップし、ユーザ権限の upgrade は継続する。
if [ "$(id -u)" -eq 0 ] || { command -v sudo >/dev/null && sudo -n true 2>/dev/null; }; then
    mise bootstrap packages upgrade -y
else
    echo "sudo is not available non-interactively. Skipping bootstrap packages upgrade."
fi

mise upgrade -y
