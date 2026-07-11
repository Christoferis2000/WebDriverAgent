// Minimalny klient na vyskusanie WebDriverAgent (WDA) z Windows PC.
//
// Windows nevie WDA zbuildovat/spustit (vyzaduje macOS + Xcode). Tento skript
// je iba KLIENT: pripoji sa na Appium/WDA endpoint (cloud farma alebo Mac),
// vytvori XCUITest session a vypise page source.
//
// Spustenie:
//   1) npm install
//   2) nastav premenne prostredia (pozri .env.example) alebo pouzi menu.mjs
//   3) node test.mjs
//
// Pozn.: .env sa NEnacitava automaticky. Premenne nastav v shelli, napr.:
//   PowerShell:  $env:APPIUM_URL = "http://192.168.1.50:4723"; node test.mjs
//
// Chces vyber z pripravenych profilov? Spusti interaktivne menu:
//   node menu.mjs      (alebo run.cmd na Windowse)

import { runSession, printFailureHints } from './session.mjs';

// Konfiguracia sa cita z premennych prostredia; buildOptions() doplni defaulty.
const config = {
  APPIUM_URL: process.env.APPIUM_URL,
  CLOUD_USER: process.env.CLOUD_USER,
  CLOUD_KEY: process.env.CLOUD_KEY,
  DEVICE_NAME: process.env.DEVICE_NAME,
  PLATFORM_VERSION: process.env.PLATFORM_VERSION,
  BUNDLE_ID: process.env.BUNDLE_ID,
  WDA_BINDING_IP: process.env.WDA_BINDING_IP,
};

runSession(config).catch((err) => {
  printFailureHints(err);
  process.exitCode = 1;
});
