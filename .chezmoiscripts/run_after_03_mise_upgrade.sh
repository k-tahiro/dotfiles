#!/bin/bash
set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "Error: mise is not installed. Please install mise first."
    exit 1
fi

mise self-update -y

# bootstrap は sudo (apt 等のシステムパッケージ) を必要とすることがある。
# 失敗しても apply 全体を止めず、ユーザ権限の upgrade は継続する。
if ! mise bootstrap packages upgrade -y; then
    echo "Warning: mise bootstrap packages upgrade failed (sudo unavailable?). Skipping." >&2
fi

mise upgrade -y
