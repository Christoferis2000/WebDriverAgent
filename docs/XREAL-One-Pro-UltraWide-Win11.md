# XREAL One Pro ako ultraširoký 32:9 monitor na Windows 11 — hĺbková analýza a návod

> Cieľ: pripojiť **XREAL One Pro (M)** k notebooku s **Windows 11** a používať ich ako
> **virtuálny ultrapanoramatický monitor 32:9 (3840 × 1080)**.
>
> Dátum analýzy: 2026-05-29

---

## 1. Tvoja zostava a čo z nej reálne treba

| Zariadenie | Úloha pri „monitor na Win11" | Potrebné? |
|---|---|---|
| **XREAL One Pro (M)** | samotný displej / okuliare, vstavaný čip **X1** | ✅ áno |
| **XREAL Eye** | prídavná kamera → odomyká **6DoF** (priestorové ukotvenie) | ⛔ nie nutné, ale výhodné (viď §7) |
| **XREAL Beam Pro** | samostatný **Android** hostiteľ/ovládač | ⛔ nie — pri pripojení k Win11 notebooku ho nepotrebuješ |

**Dôležité:** Notebook s Windows 11 je hostiteľ (zdroj obrazu). Beam Pro je alternatívny
Android hostiteľ — pre „monitor k notebooku" ho **vynecháš**.

---

## 2. Ako vlastne vzniká 32:9 obraz (technické jadro)

Toto je kľúčové pochopiť, aby ti nastavenie dávalo zmysel:

- Okuliare majú **2× Sony Micro-OLED 1920 × 1080 na oko**, **120 Hz**, **FOV 57°**, jas ~700 nitov.
- Vstavaný čip **X1** robí všetko **natívne v okuliaroch** — žiadny Nebula softvér ani ovládač
  pre Windows sa neinštaluje. (Nebula pre desktop séria One/One Pro **nepoužíva**.)
- V **bežnom režime** sa okuliare hlásia Windowsu ako **1920 × 1080** displej (plávajúce „171\""
  plátno).
- V **Ultra-Wide režime** okuliare prepnú vstup na **3840 × 1080 (pomer 32:9)**. Windows odvtedy
  „vidí" monitor s rozlíšením 3840 × 1080 a X1 ho vykreslí ako **zakrivené ultraširoké plátno
  (ekvivalent ~310\")**.

### Najdôležitejšie obmedzenie — FOV 57°
Zorné pole okuliarov je **57°**, takže **celých 32:9 NEUVIDÍŠ naraz**. Plátno je širšie než
tvoj výhľad → po ploche **„prechádzaš" otáčaním hlavy** (ako keď točíš hlavou pred fyzickým
ultrawide monitorom). To je úplne iný zážitok než reálny 49\" 32:9 panel, kde okraje vidíš
periférne. Toto je najväčší praktický kompromis — počítaj s ním.

### Ostrosť
Pri 3840 × 1080 sa horizontálne pixely „roztiahnu" cez široké plátno → **menšia hustota
pixelov a jemne mäkší text** než pri sústredenom 1080p plátne. Pre kód/text je to použiteľné,
ale ostrejšie je bežné 1920 × 1080 plátno.

### 3DoF vs 6DoF
Samotné okuliare (bez modulu **Eye**) zvládajú len **3DoF** — sledujú **otočenie** hlavy,
nie posun tela. Ukotvené plátno teda „drží smer", ale pri naklonení/posune trupom sa nepohne
korektne s priestorom. Modul **XREAL Eye** pridáva **6DoF** → plátno ostáva pevne „zavesené
v miestnosti" aj keď sa pohneš (viď §7).

---

## 3. Hardvérová podmienka pripojenia (over PRED nákupom čohokoľvek)

Okuliare potrebujú z notebooku **digitálny video signál + napájanie cez jeden USB-C**:

> **USB-C s podporou „DisplayPort Alt Mode" (DP Alt Mode) + napájanie.**

Nie každý USB-C port to vie! Ako overiť na Win11 notebooku:

1. **Špecifikácia výrobcu** — pri USB-C porte musí byť uvedené *DisplayPort*, *DP Alt Mode*,
   alebo symbol **Thunderbolt (⚡)** / **DisplayPort (D↦)** pri konektore.
2. **Praktický test** — ak cez ten istý USB-C port funguje pripojenie na bežný externý monitor
   (USB-C → HDMI/DP), DP Alt Mode tam je.
3. **Thunderbolt 3/4 a USB4 porty** DP Alt Mode podporujú vždy.

### Možnosti podľa portov notebooku

| Situácia na notebooku | Riešenie |
|---|---|
| **USB-C s DP Alt Mode** (ideál) | Priamo priložený **USB-C ↔ USB-C** kábel. Hotovo. |
| **Len HDMI**, USB-C bez videa / žiadny USB-C | **HDMI → USB-C adaptér** pre AR okuliare (napr. KIHENG a pod.). Pozor: HDMI neprenáša napájanie → adaptér väčšinou má **vlastný USB-C vstup na napájanie**, ktorý treba zapojiť. |
| **Slabý/úsporný USB-C** (nedá dosť prúdu) | Použi **USB-C s napájaním** alebo adaptér s externým napájaním. |

> ⚠️ Cez HDMI adaptér často **stratíš 120 Hz** (HDMI 2.0 zvládne 3840×1080 typicky do 60 Hz).
> Natívny USB-C DP Alt Mode je vždy lepší.

---

## 4. Ovládanie okuliarov (tlačidlá na pravom ramene)

| Tlačidlo | Akcia | Funkcia |
|---|---|---|
| **X (červené)** – vpredu pod pravým ramenom | 1× klik | prepnúť **Anchor ↔ Follow** |
| | dlhé podržanie | **vycentrovať** plátno priamo pred teba |
| | 2× klik | otvoriť **menu na obrazovke** |
| **+ / −** lišta (za X) | klik | **jas** displeja |
| | dlhé podržanie | **elektrochromické tienenie** (level 1 = mierne stmavenie okolia … level 3 = úplný blackout) |
| **Quick** (krátke tlačidlo navrchu ramena) | 1× klik | **Transparency Mode** (vypne displej, vidíš okolie) |
| | dlhé podržanie | vlastná (konfigurovateľná) funkcia |

### Režimy plátna
- **Polohové režimy:** **Anchor** (plátno zostáva ukotvené v priestore) a **Follow**
  (plátno sleduje pohľad).
- **Režimy obrazovky:** Default, **Ultra-Wide**, Side View, 3D.

**Pre „monitor" je najlepší `Anchor`** — plátno visí na mieste a ty sa po 32:9 pozeráš
otáčaním hlavy. `Follow` je vhodný na chôdzu/čítanie, kde má plátno ísť stále s tebou.

---

## 5. Postup nastavenia krok za krokom (Windows 11)

1. **Skontroluj port** podľa §3 (DP Alt Mode). Priprav správny kábel/adaptér.
2. **Zapoj kábel** do USB-C portu na **zadnej časti ľavého ramena** okuliarov, druhý koniec do
   notebooku. Obraz sa v okuliaroch objaví o pár sekúnd (žiadna inštalácia ovládača netreba).
3. Windows zachytí nový displej (default **1920 × 1080**). Stlač **`Win + P`** a zvoľ:
   - **Extend** (Rozšíriť) — chceš okuliare ako *ďalší* pracovný priestor, **alebo**
   - **Second screen only** (Len druhá obrazovka) — chceš pracovať *iba* v okuliaroch
     (ideál na sústredenie / cestovanie).
4. **Zapni Ultra-Wide v okuliaroch:**
   `2× klik na X` → záložka **Display** → **Ultra-Wide Mode** → potvrď **klikom na X**.
   Okuliare prepnú výstup na **3840 × 1080**.
5. **Nastav rozlíšenie vo Windows:**
   *Nastavenia → Systém → Obrazovka* → vyber displej okuliarov → **Rozlíšenie obrazovky =
   3840 × 1080**. (Ak sa hneponúka hneď, odpoj/zapoj kábel po kroku 4, aby Windows znova
   načítal EDID.)
6. **Mierka (Scale):** pri 3840 × 1080 nechaj **100 %** — viac miesta na okná. Ak je text
   primalý, skús 125 %.
7. **Polohový režim:** klikni **X** kým nie si v **Anchor**, potom dlho podrž **X** na
   vycentrovanie plátna pred seba.
8. **Jas a tienenie:** **+/−** na jas; dlhé podržanie **+/−** na stmavenie okolia (level 3 =
   blackout pre maximálny kontrast a sústredenie).

---

## 6. Optimalizácia práce na 32:9 plátne (Windows)

- **PowerToys → FancyZones:** rozdeľ 3840 × 1080 na napr. 3 stĺpce (1280 px) alebo 2× 1920 px.
  Okná potom `Shift`+ťahanie prichytávaš do zón → ultrawide sa správa ako 2–3 monitory vedľa seba.
  Toto je najväčší „quality-of-life" tip pre ultrawide.
- **Win + šípky** na rýchle dlaždicovanie polovice/štvrtiny.
- **Anchor + vycentrovanie** pred začiatkom práce; stred plátna nech je „primárna" oblasť,
  bočné panely (chat, dokumentácia, terminál) daj do krajov, kam sa pozrieš otočením hlavy.
- **Refresh:** over v *Rozšírené nastavenia obrazovky*, či ide 90/120 Hz; cez HDMI adaptér
  to môže byť 60 Hz.

---

## 7. Kedy zapojiť XREAL Eye (6DoF)

Bez Eye: **3DoF** — ukotvené plátno reaguje len na **otočenie** hlavy. Keď sa nakloníš alebo
posunieš na stoličke, plátno sa „nezadrží" v priestore správne.

S **XREAL Eye**: **6DoF** — plátno zostáva **pevne zavesené v miestnosti** aj pri pohybe trupu,
čo pri ultrawide výrazne zvýši pocit „skutočného monitora". Ak plánuješ dlhé sedenie s
ukotveným 32:9 plátnom, Eye sa oplatí pripnúť. Pre čisto statické sedenie (Follow režim alebo
„len pozerám rovno") nie je nutný.

---

## 8. Riešenie problémov

| Problém | Príčina / riešenie |
|---|---|
| Okuliare nič nezobrazia | USB-C port **nemá DP Alt Mode** → použi iný port alebo HDMI→USB-C adaptér s napájaním. |
| Obraz je, ale tmavý / bliká | málo prúdu z portu → adaptér s externým napájaním, iný kábel. |
| Ultra-Wide sa nedá vybrať vo Windows | najprv zapni Ultra-Wide v okuliaroch (§5.4), **potom** znovu zapoj kábel, aby Windows načítal nové EDID 3840×1080. |
| Plátno „pláva" / nedrží | si vo **Follow** → prepni **X** na **Anchor**, dlho podrž **X** na vycentrovanie. |
| Max 60 Hz namiesto 120 | ideš cez **HDMI 2.0 adaptér** → prejdi na natívny USB-C DP Alt Mode. |
| Plátno sa pri pohybe tela posúva nesprávne | len 3DoF → pripni **XREAL Eye** pre 6DoF (§7). |
| Rozmazaný text | dôsledok roztiahnutia 1080p cez 32:9; skús mierku 125 % alebo pre čítanie prepni na Default 1920×1080 režim. |

---

## 9. Realistické očakávania (zhrnutie kompromisov)

✅ **Funguje dobre:** prenosný „veľký" pracovný priestor, súkromie (nikto nevidí obrazovku),
sústredenie (blackout level 3), náhrada za viac monitorov na cestách.

⚠️ **Kompromisy:**
- **57° FOV** → 32:9 vidíš len po častiach, prechádzaš hlavou (nie periférne ako fyzický panel).
- Ostrosť 32:9 je nižšia než sústredené 1080p.
- Bez **Eye** len 3DoF.
- Dlhšie nosenie môže unavovať oči/krk; rob prestávky.

---

## 10. Rýchly checklist

- [ ] Notebook USB-C má **DP Alt Mode** (alebo mám HDMI→USB-C adaptér s napájaním)
- [ ] Zapojiť kábel do **ľavého ramena** okuliarov
- [ ] `Win + P` → **Extend** alebo **Second screen only**
- [ ] V okuliaroch: `2× X` → Display → **Ultra-Wide** → X
- [ ] Windows: rozlíšenie **3840 × 1080**, mierka 100 %
- [ ] `X` → **Anchor**, dlhé podržanie `X` = vycentrovať
- [ ] (voliteľné) **FancyZones** na rozdelenie plochy
- [ ] (voliteľné) pripnúť **XREAL Eye** pre 6DoF

---

### Zdroje
- XREAL One Pro – oficiálny produkt: <https://us.shop.xreal.com/products/xreal-one-pro>
- XREAL One Series – User Guide: <https://us.shop.xreal.com/blogs/buying-guide/user-guide_xreal-one-series>
- XREAL One Pro User Manual (PDF): <https://www.richersounds.com/content/product_files/XREALOneProUserManual_1758685354840_8n16q.pdf>
- VR-Compare špecifikácie: <https://vr-compare.com/headset/xrealonepro>
- Digital Trends – XREAL One review: <https://www.digitaltrends.com/computing/xreal-one-review/>
- How-To Geek – XREAL One review: <https://www.howtogeek.com/xreal-one-ar-glasses-review/>
- INAIRSPACE – kompatibilita/pripojenie: <https://inairspace.com/blogs/learn-with-inair/xreal-air-supported-devices-the-complete-compatibility-and-setup-guide>
