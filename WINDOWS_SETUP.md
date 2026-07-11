# Setup WebDriverAgent na Windows PC (sprievodca v slovenčine)

Tento dokument vysvetľuje, ako si na **Windows PC** pripraviť prostredie na
**vyskúšanie WebDriverAgent (WDA)**. Je písaný pre niekoho, kto WDA ešte nepoužíval.

---

## 1. Najdôležitejšie na úvod: čo sa dá a čo nie

WebDriverAgent je WebDriver server pre iOS/tvOS, ktorý je postavený na Apple
`XCTest.framework` a **stavia sa výhradne cez `xcodebuild`**. To znamená:

> ⚠️ **WDA sa NEDÁ zostaviť ani spustiť priamo na Windowse.** Build vyžaduje macOS
> a Xcode. Na Windowse neexistuje žiadny podporovaný spôsob, ako WDA skompilovať.

Čo teda **na Windowse robiť môžeš**: byť **klient** — písať a púšťať automatizačné
testy (cez Appium / WebdriverIO), ktoré sa pripájajú na WDA bežiaci niekde inde.

WDA (a s ním iOS automatizácia) musí bežať na jednom z troch miest:

```
   [ Tvoj Windows PC ]                        [ WDA hostuje ... ]
   ┌───────────────────┐                      ┌──────────────────────────────┐
   │ Node.js + klient  │   HTTP (Appium/W3C)  │  A) Cloudová device farm     │
   │ (WebdriverIO)     │ ───────────────────► │     (BrowserStack/Sauce/...)  │
   │ test.mjs          │                      │        alebo                  │
   │                   │                      │  B) Mac s Xcode + Appium       │
   └───────────────────┘                      │     server + iPhone/simulátor │
                                              └──────────────────────────────┘
```

Podľa toho, či máš prístup k Macu, si vyber jednu z dvoch ciest.

---

## 2. Čo maj nainštalované na Windows PC (spoločné pre obe cesty)

Tieto veci potrebuješ na Windowse tak či tak, lebo Windows je vždy len klient:

- [ ] **Node.js LTS** (verzia 20+). Over: `node -v` a `npm -v`.
- [ ] **Git** (na klonovanie a prácu s repom).
- [ ] Editor kódu (napr. **VS Code**).
- [ ] *(voliteľné)* **Appium Inspector** — GUI na prehliadanie prvkov appky:
      https://github.com/appium/appium-inspector/releases

Poznámky:
- Appium server (`npm i -g appium`) a XCUITest driver
  (`appium driver install xcuitest`) sa **reálne používajú len na Macu** (Cesta B).
  Na Windowse ich inštalovať nemusíš, ak ideš Cestou A (cloud) alebo ak Appium
  server beží na Macu.
- Ak by si chcel na Windowse spustiť lokálny Appium server, ktorý riadi vzdialený
  Mac, je to pokročilý scenár — pre „len vyskúšať" ho neodporúčam.

---

## 3. Cesta A — ODPORÚČANÁ bez Macu: cloudová device farm

Toto je najrýchlejšia cesta „spustiť a vidieť, že to žije", ak **nemáš Mac**.
Farma (napr. **BrowserStack**, **Sauce Labs**, **LambdaTest**) hostuje reálne
iOS zariadenia aj WDA za teba. Ty z Windowsu posielaš len testovaciu session.

Kroky:

1. Zaregistruj sa na jednej z fariem (majú free/trial plány) a získaj:
   - `username` / `access key` (alebo API token),
   - URL endpointu (napr. `https://hub-cloud.browserstack.com/wd/hub`).
2. Priprav si klienta na Windowse — pozri priečinok
   [`examples/windows-client/`](examples/windows-client/) v tomto repe.
3. Vyplň prihlasovacie údaje a spusti test. Farma sama nasadí WDA na zariadenie.

Výhody: žiadny Mac, žiadny build, žiadne podpisovanie.
Nevýhody: potrebuje účet (často platený nad rámec trialu) a internet.

---

## 4. Cesta B — ak máš (alebo si zaobstaráš) Mac

Ak máš **fyzický Mac** alebo **cloudový Mac** (napr. MacStadium, Scaleway Mac mini),
WDA postavíš tam a Windows sa naň pripojí.

### 4a. Na Macu (jednorazová príprava)

1. Nainštaluj **Xcode** (16.x) z App Store a spusti ho aspoň raz (súhlas s licenciou).
2. Nainštaluj **Node.js 20+**.
3. Naklonuj tento repozitár a nainštaluj závislosti:
   ```bash
   git clone https://github.com/appium/WebDriverAgent.git
   cd WebDriverAgent
   npm install
   ```
4. Máš tri možnosti, ako získať/rozbehať WDA:
   - **Najjednoduchšie (odporúčané):** nechaj to na Appium. Nainštaluj Appium a
     XCUITest driver, ktorý si WDA postaví a nasadí sám:
     ```bash
     npm i -g appium
     appium driver install xcuitest
     appium        # spustí server na porte 4723
     ```
   - **Manuálny build simulátorového bundle:**
     ```bash
     npm run bundle
     ```
     (interne volá `Scripts/build-webdriveragent.mjs` → `Scripts/build.sh` →
     `xcodebuild`; simulátor nevyžaduje podpisovanie).
   - **Vývoj/debug v Xcode:** otvor `WebDriverAgent.xcodeproj`, vyber scheme
     `WebDriverAgentRunner` a spusti test (Run). Toto je popísané aj v `README.md`.
   - *(voliteľné)* stiahnuť hotové binárky namiesto buildu:
     ```bash
     npm run fetch-prebuilt-wda
     ```
5. **Reálne iOS zariadenie** navyše vyžaduje **code signing**: v Xcode nastav
   *Team* a *Provisioning profile* pre target `WebDriverAgentRunner` (Signing &
   Capabilities). Simulátor podpisovanie nepotrebuje.
6. Zisti IP adresu Macu v lokálnej sieti (`ipconfig getifaddr en0`).

### 4b. Na Windowse

1. Nastav v klientovi endpoint na Mac: `APPIUM_URL=http://<IP-Macu>:4723`.
2. Spusti test z [`examples/windows-client/`](examples/windows-client/).
3. Mac aj Windows musia byť v rovnakej sieti a port `4723` nesmie blokovať firewall.

---

## 5. Referencie v tomto repe (kde sa čo deje)

- `README.md` — oficiálny getting-started (Node + otvoriť `.xcodeproj`, `npm run bundle`).
- `Scripts/build.sh`, `Scripts/build-webdriveragent.mjs` — ako sa WDA reálne stavia (Mac).
- `Scripts/fetch-prebuilt-wda.mjs` — sťahovanie hotových binárok (`npm run fetch-prebuilt-wda`).
- `lib/constants.ts` — scheme `WebDriverAgentRunner`, bundle id
  `com.facebook.WebDriverAgentRunner`, SDK `iphonesimulator` / `iphoneos`.
- `package.json` — `engines` (Node ≥20) a npm skripty (`bundle`, `fetch-prebuilt-wda`).

---

## 6. Časté problémy

| Problém | Príčina / riešenie |
|--------|--------------------|
| „Chcem WDA zbuildovať na Windowse" | Nedá sa — vyžaduje macOS + Xcode. Použi Cestu A alebo B. |
| Session sa nevytvorí (Cesta B) | Skontroluj IP Macu, port 4723, firewall, či beží `appium`. |
| Reálne zariadenie hlási signing error | Nastav Team + Provisioning profile v Xcode (Signing & Capabilities). |
| Nesúlad verzií Xcode / iOS | WDA CI používa Xcode 16.4; staršie verzie nemusia zbuildovať. |
| Cloud session padá na autentifikácii | Over `username`/`access key` a správnu URL endpointu farmy. |

---

Hotovo. Pre reálny spustiteľný príklad klienta pokračuj do
[`examples/windows-client/`](examples/windows-client/).
