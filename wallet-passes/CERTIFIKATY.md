# Apple Wallet - Možnosti získania certifikátov

## 1. Apple Developer Account (99 $/rok) — ODPORÚČANÉ

Jediná oficiálne podporovaná metóda.

### Postup:
1. Registrácia na [developer.apple.com](https://developer.apple.com) (99 $/rok)
2. **Certificates, Identifiers & Profiles → Identifiers → + → Pass Type IDs**
3. Zadať identifikátor, napr. `pass.com.vasadomena.pulsation`
4. **Certificates → + → Pass Type ID Certificate**
5. Vytvoriť CSR (Certificate Signing Request):
   - macOS: Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   - Saved to disk → nahrať na portál
6. Stiahnuť certifikát (`.cer`), importovať do Keychain Access
7. Exportovať ako `.p12` → konvertovať na `.pem`:
   ```bash
   openssl pkcs12 -in pass.p12 -clcerts -nokeys -out certs/signerCert.pem
   openssl pkcs12 -in pass.p12 -nocerts -out certs/signerKey.pem
   ```
8. Stiahnuť Apple WWDR certifikát:
   ```bash
   curl -o certs/wwdr.pem https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer
   openssl x509 -inform DER -in certs/wwdr.pem -out certs/wwdr.pem
   ```
9. Spustiť `node generate-passes.js`

**Výhody:** Plná kontrola, oficiálne podporované
**Nevýhody:** 99 $/rok

---

## 2. Online služby (bez vlastného certifikátu)

Tieto služby majú vlastný Apple certifikát a podpisujú pasy za vás:

| Služba | Bezplatný plán | Poznámka |
|--------|----------------|----------|
| **PassKit** (passkit.com) | Áno (limitovaný) | API + dashboard, Apple aj Google Wallet |
| **Passcreator** (passcreator.com) | Skúšobná verzia | GDPR, drag-and-drop editor |
| **PassSlot** (passslot.com) | Áno (limitovaný) | REST API + web |
| **Pass2U Wallet** (iOS app) | Áno | Priamo na iPhone, najjednoduchšie |

### Pass2U Wallet — najrýchlejšia cesta:
1. Stiahnuť **Pass2U Wallet** z App Store
2. Vytvoriť nový pass → Event Ticket
3. Vyplniť údaje (názov, dátum, miesto, QR kód)
4. Uložiť do Apple Wallet

---

## 3. Google Wallet (ZADARMO)

Úplne bezplatná alternatíva pre Android používateľov.

1. Vytvoriť Google Cloud účet
2. Aktivovať Google Wallet API
3. Vytvoriť Service Account
4. Použiť Google Wallet REST API na vytvorenie passu

**Výhody:** Zadarmo, bez certifikátov
**Nevýhody:** Len pre Android/Google Wallet

---

## 4. Bezplatný Apple Developer účet

**NIE JE MOŽNÉ.** Bezplatný účet neposkytuje prístup k Pass Type IDs.

---

## 5. Open source knižnice (vyžadujú certifikát z bodu 1)

| Knižnica | Jazyk | NPM/PIP |
|----------|-------|---------|
| **passkit-generator** | Node.js | `npm i passkit-generator` |
| **php-pkpass** | PHP | `composer require pkpass/pkpass` |
| **wallet/passbook** | Python | `pip install wallet` |
| **passbook** | Ruby | `gem install passbook` |

---

## Odporúčanie

| Situácia | Riešenie |
|----------|----------|
| Rýchlo, jednorazovo | **Pass2U Wallet** (iOS app) |
| Bez investície, Android | **Google Wallet API** (zadarmo) |
| Seriózny projekt | **Apple Developer Account** (99 $/rok) |
| Server-side generovanie | Apple certifikát + `passkit-generator` |
