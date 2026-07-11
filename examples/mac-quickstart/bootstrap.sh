#!/usr/bin/env bash
#
# mac-quickstart/bootstrap.sh
#
# Jednorazovy skript na MACU, ktory rychlo pripravi prostredie na hostovanie
# WebDriverAgent (WDA) cez Appium, aby sa nan mohol pripojit klient z Windows PC
# (alebo lokalne z Macu).
#
# Robi:
#   1. overi Node >=20 a pritomnost Xcode,
#   2. nainstaluje zavislosti repa (npm install),
#   3. nainstaluje Appium + XCUITest driver (idempotentne),
#   4. vypise lokalnu IP a hotove APPIUM_URL na skopirovanie do Windows klienta,
#   5. spusti Appium server na porte 4723.
#
# Pouzitie:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh
#
# Pozn.: WDA sa NEbinduje sam - to riesi klient cez capability appium:wdaBindingIP
# (pozri examples/windows-client). Kvoli bezpecnosti drz WDA na 127.0.0.1 (USB-only).

set -euo pipefail

# Prejdi do korena repa (dve urovne nad tymto skriptom).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

APPIUM_PORT="${APPIUM_PORT:-4723}"

info()  { printf '\033[0;34m[i]\033[0m %s\n' "$1"; }
ok()    { printf '\033[0;32m[✓]\033[0m %s\n' "$1"; }
warn()  { printf '\033[0;33m[!]\033[0m %s\n' "$1"; }
fail()  { printf '\033[0;31m[x]\033[0m %s\n' "$1" >&2; exit 1; }

# --- 1. Kontrola prostredia ---------------------------------------------------

info "Kontrolujem operacny system..."
if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "Tento skript je urceny pre macOS. WDA sa neda buildovat/hostovat na Windowse ani Linuxe."
fi

info "Kontrolujem Node.js (>=20)..."
if ! command -v node >/dev/null 2>&1; then
  fail "Node.js nie je nainstalovany. Nainstaluj Node 20+ (https://nodejs.org) a spusti znova."
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if (( NODE_MAJOR < 20 )); then
  fail "Node.js verzia je prilis stara ($(node -v)). Potrebujes Node >=20."
fi
ok "Node $(node -v)"

info "Kontrolujem Xcode..."
if ! command -v xcodebuild >/dev/null 2>&1; then
  fail "Xcode / command line tools nie su k dispozicii. Nainstaluj Xcode z App Store a spusti ho aspon raz."
fi
if ! xcode-select -p >/dev/null 2>&1; then
  fail "xcode-select nie je nastaveny. Spusti: sudo xcode-select --switch /Applications/Xcode.app"
fi
ok "Xcode: $(xcodebuild -version | head -n1)"

# --- 2. Zavislosti repa -------------------------------------------------------

info "Instalujem zavislosti repa (npm install) v ${REPO_ROOT}..."
( cd "${REPO_ROOT}" && npm install )
ok "Zavislosti repa nainstalovane."

# --- 3. Appium + XCUITest driver ---------------------------------------------

if ! command -v appium >/dev/null 2>&1; then
  info "Instalujem Appium globalne (npm i -g appium)..."
  npm install -g appium
  ok "Appium nainstalovany."
else
  ok "Appium uz je nainstalovany ($(appium -v))."
fi

info "Kontrolujem XCUITest driver..."
if appium driver list --installed 2>/dev/null | grep -q 'xcuitest'; then
  ok "XCUITest driver uz je nainstalovany."
else
  info "Instalujem XCUITest driver..."
  appium driver install xcuitest
  ok "XCUITest driver nainstalovany."
fi

# --- 4. Vypis pripojenia ------------------------------------------------------

LOCAL_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo '')"

echo
ok "Prostredie je pripravene."
echo   "----------------------------------------------------------------------"
info "Na Windows PC nastav v kliente (examples/windows-client) endpoint:"
if [[ -n "${LOCAL_IP}" ]]; then
  echo   "    APPIUM_URL = http://${LOCAL_IP}:${APPIUM_PORT}"
else
  warn "Nepodarilo sa zistit lokalnu IP (en0/en1). Zisti ju cez: ipconfig getifaddr en0"
  echo   "    APPIUM_URL = http://<IP-tohto-Macu>:${APPIUM_PORT}"
fi
echo
info "Bezpecnost: v kliente nechaj WDA_BINDING_IP=127.0.0.1 (WDA len cez USB, nie WiFi)."
warn "Port ${APPIUM_PORT} bude na LAN - chran ho firewallom a pouzivaj doveryhodnu siet."
info "Najbezpecnejsie: spusti klienta priamo tu na Macu (APPIUM_URL=http://127.0.0.1:${APPIUM_PORT})."
echo   "----------------------------------------------------------------------"
echo

# --- 5. Spustenie Appium servera ---------------------------------------------

info "Spustam Appium server na porte ${APPIUM_PORT} (ukoncis cez Ctrl+C)..."
exec appium --port "${APPIUM_PORT}"
