#!/bin/bash
set -euo pipefail

if ! command -v apm &> /dev/null; then
    echo "Error: apm is not installed. Please install mise first."
    exit 1
fi

apm install --global
