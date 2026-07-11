# WDA Windows klient — príklad

Minimálny spustiteľný klient, ktorý z **Windows PC** overí, že WebDriverAgent
(WDA) funguje. Windows je tu len klient — WDA musí bežať na **Macu** alebo v
**cloudovej device farme** (viď [`../../WINDOWS_SETUP.md`](../../WINDOWS_SETUP.md)).

## Predpoklady

- Node.js 20+ na Windowse (`node -v`).
- Bežiaci WDA/Appium endpoint (jedna z ciest v `WINDOWS_SETUP.md`).

## Spustenie

```powershell
npm install

# Cesta B — Mac v lokálnej sieti (Appium beží na Macu na porte 4723):
$env:APPIUM_URL = "http://192.168.1.50:4723"
node test.mjs

# Cesta A — cloud device farm (príklad BrowserStack):
$env:APPIUM_URL = "https://hub-cloud.browserstack.com/wd/hub"
$env:CLOUD_USER = "tvoj_user"
$env:CLOUD_KEY  = "tvoj_key"
node test.mjs
```

Premenné, ktoré vieš nastaviť, sú v [`.env.example`](.env.example)
(`APPIUM_URL`, `CLOUD_USER`, `CLOUD_KEY`, `DEVICE_NAME`, `PLATFORM_VERSION`,
`BUNDLE_ID`).

## Čo skript robí

1. Pripojí sa na zadaný Appium/WDA endpoint.
2. Vytvorí XCUITest session (predvolene otvorí appku Nastavenia — `com.apple.Preferences`).
3. Vypíše ukážku page source → dôkaz, že automatizácia cez WDA funguje.
4. Session korektne ukončí.

Ak session zlyhá, skript vypíše konkrétne tipy (firewall, port, cloud kľúče,
verzia zariadenia).
