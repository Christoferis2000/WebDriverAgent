# Mac quick-start — rýchla adaptácia na Mac

Keď získaš prístup k **Macu**, tento skript pripraví hostovanie WebDriverAgent
(WDA) cez Appium **jedným príkazom**, aby sa naň mohol pripojiť klient z Windows PC
(alebo lokálne z Macu).

## Spustenie (na Macu)

```bash
cd examples/mac-quickstart
chmod +x bootstrap.sh
./bootstrap.sh
```

Skript:
1. overí Node ≥20 a prítomnosť Xcode,
2. spustí `npm install` v koreni repa,
3. nainštaluje Appium + XCUITest driver (preskočí, ak už sú),
4. vypíše lokálnu IP a hotové `APPIUM_URL` na skopírovanie do Windows klienta,
5. spustí Appium server na porte `4723`.

## Prepojenie s Windows klientom

Na Windowse potom v [`../windows-client/`](../windows-client/) stačí nastaviť
vypísané `APPIUM_URL` a spustiť `node test.mjs`. Klient sa nemení — je to tá istá
zmena jednej premennej, o ktorej hovorí [`../../WINDOWS_SETUP.md`](../../WINDOWS_SETUP.md).

## Bezpečnosť

- V klientovi nechaj `WDA_BINDING_IP=127.0.0.1` → WDA na zariadení je dostupné **iba
  cez USB**, nie cez WiFi (WDA nemá autentifikáciu ani TLS).
- Port `4723` (Appium) bude na LAN — chráň ho firewallom a dôveryhodnou sieťou.
- **Najbezpečnejšie:** spusti klienta priamo na Macu
  (`APPIUM_URL=http://127.0.0.1:4723`) — vtedy nič neopúšťa Mac ani USB.

Podrobnosti v sekcii „Bezpečnosť" v [`../../WINDOWS_SETUP.md`](../../WINDOWS_SETUP.md).
