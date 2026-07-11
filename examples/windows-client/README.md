# WDA Windows klient — príklad

Minimálny spustiteľný klient, ktorý z **Windows PC** overí, že WebDriverAgent
(WDA) funguje. Windows je tu len klient — WDA musí bežať na **Macu** alebo v
**cloudovej device farme** (viď [`../../WINDOWS_SETUP.md`](../../WINDOWS_SETUP.md)).

## Predpoklady

- Node.js 20+ na Windowse (`node -v`).
- Bežiaci WDA/Appium endpoint (jedna z ciest v `WINDOWS_SETUP.md`).

## Spustenie A — interaktívne menu (výber projektu) — odporúčané

Po spustení sa zobrazí zoznam pripravených „projektov" (profilov) a vyberieš si číslo:

```powershell
npm install

# Windows (cmd alebo dvojklik):
run.cmd

# alebo priamo cez Node (macOS/Linux: ./run.sh):
node menu.mjs

# Neinteraktívne — rovno vyber projekt č. 2:
node menu.mjs 2
```

Profily sú v [`projects.json`](projects.json) — pokojne si pridaj vlastný (skopíruj
existujúci blok a uprav `name`, `APPIUM_URL`, `DEVICE_NAME`, `BUNDLE_ID`, …).
Pre cloud profil sa `CLOUD_USER`/`CLOUD_KEY` doplnia z premenných prostredia, inak
sa na ne menu opýta.

## Spustenie B — priamo cez premenné prostredia

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
`BUNDLE_ID`, `WDA_BINDING_IP`).

## Súbory

- `menu.mjs` — interaktívne menu na výber projektu.
- `test.mjs` — jednoduchý env-based klient (bez menu).
- `session.mjs` — spoločná logika (zostavenie capabilities + spustenie session).
- `projects.json` — uložené profily.
- `run.cmd` / `run.sh` — spúšťače menu.

## Čo klient robí

1. Pripojí sa na zadaný Appium/WDA endpoint.
2. Vytvorí XCUITest session (predvolene otvorí appku Nastavenia — `com.apple.Preferences`).
3. Vypíše ukážku page source → dôkaz, že automatizácia cez WDA funguje.
4. Session korektne ukončí.

Ak session zlyhá, klient vypíše konkrétne tipy (firewall, port, cloud kľúče,
verzia zariadenia).

## Bezpečnosť (stručne)

Reálne zariadenie sa oslovuje **cez USB** (klient ide na `127.0.0.1`).
`WDA_BINDING_IP=127.0.0.1` je doplnkový zámok, aby WDA nebolo vidno na WiFi (port
8100) — WDA nemá auth ani TLS. Detaily v sekcii „Bezpečnosť" v
[`../../WINDOWS_SETUP.md`](../../WINDOWS_SETUP.md).
