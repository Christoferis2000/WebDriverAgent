#!/usr/bin/env bash
# Spustac interaktivneho menu na macOS/Linuxe.
# Zobrazi vyber projektu z projects.json a spusti session.
# Volitelne: ./run.sh 2  -> rovno vyber projekt cislo 2.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${HERE}"

if ! command -v node >/dev/null 2>&1; then
  echo "[x] Node.js nie je nainstalovany. Nainstaluj Node 20+ a spusti znova."
  exit 1
fi

if [[ ! -d node_modules ]]; then
  echo "[i] Instalujem zavislosti (npm install)..."
  npm install
fi

exec node "${HERE}/menu.mjs" "$@"
