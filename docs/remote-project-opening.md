# Návrh: Otváranie projektov cez remote + „open" launcher

> Stav: **Návrh (proposal)** — dokument popisuje architektúru a API. Neobsahuje
> produkčnú implementáciu; slúži ako podklad na odsúhlasenie pred kódovaním.
>
> Autor: automatizovaný návrh (Claude Code) · Vetva: `claude/remote-project-opening-lnlxoz`

## 1. Cieľ

Umožniť, aby sa na spravovanom iOS/tvOS zariadení dal **vzdialene (remote) otvoriť
konkrétny „projekt"** v cieľovej („launcher") aplikácii jediným HTTP volaním voči
bežiacemu WebDriverAgent (WDA) serveru.

„Projekt" je v tomto dokumente ľubovoľná entita, ktorú launcher aplikácia vie
adresovať identifikátorom (napr. `projectId`, cesta, alebo URL slug) a otvoriť ju
cez vlastnú **URL schému / universal link** (deep link).

„Remote" znamená, že spúšťač celej akcie je mimo zariadenia — typicky backend,
CI job alebo operátorský nástroj, ktorý pošle HTTP request na WDA endpoint.

## 2. Východiská — čo WDA už dnes vie

WDA má tri relevantné, už existujúce mechanizmy. Návrh na nich stavia a nič z nich
neláme.

| Mechanizmus | Route | Zdroj | Čo robí |
|---|---|---|---|
| Otvorenie URL / deep link | `POST /url` | `WebDriverAgentLib/Commands/FBSessionCommands.m:39` (`handleOpenURL:`) | Otvorí URL default aplikáciou, alebo s explicitným `bundleId`. |
| Spustenie appky v rámci session | `POST /wda/apps/launch` | `WebDriverAgentLib/Commands/FBSessionCommands.m:41` (`handleSessionAppLaunch:`) | `XCUIApplication launch` cez XCTest, viazané na aktívnu session. |
| „Unattached" spustenie appky | `POST /wda/apps/launchUnattached` | `WebDriverAgentLib/Commands/FBCustomCommands.m:66` (`handleLaunchUnattachedApp:`) | Spustí appku cez `LSApplicationWorkspace`, bez XCTest naviazania — appka nie je automatizovaná. |

Kľúčové detaily z kódu:

- `handleOpenURL:` (`FBSessionCommands.m:62`) prijíma `url` (povinné), voliteľne
  `bundleId` a `idleTimeoutMs`. Bez `bundleId` otvorí URL default aplikáciou;
  s `bundleId` cielene v danej aplikácii a vie počkať na jej ustálenie
  (`fb_waitUntilStableWithTimeout`).
- Nižšie `fb_openUrl:` (`XCUIDevice+FBHelpers.m:207`) reálne otvára URL cez
  `FBXCTestDaemonsProxy openDefaultApplicationForURL:` a má fallback cez Siri
  (`Open {url}`) pre staršie prostredia.
- `fb_openUrl:withApplication:` (`XCUIDevice+FBHelpers.m:238`) otvorí URL priamo
  konkrétnym `bundleId`.

Záver: **deep link cez `POST /url` je najpriamejšia cesta na „otvorenie projektu"**,
ak launcher aplikácia registruje URL schému alebo universal link.

## 3. Návrhy riešenia

Predkladáme tri varianty od najlacnejšieho (žiadna zmena kódu) po najkomfortnejší
(nový dedikovaný endpoint). Odporúčanie je nižšie.

### Variant A — Použiť existujúce endpointy (žiadna zmena WDA)

Launcher aplikácia zaregistruje URL schému, napr. `mylauncher://`, s tvarom:

```
mylauncher://open?projectId=<ID>
```

Klient (backend/CI) pošle:

```http
POST /url HTTP/1.1
Content-Type: application/json

{
  "url": "mylauncher://open?projectId=42",
  "bundleId": "eu.el-iv.mylauncher",
  "idleTimeoutMs": 5000
}
```

- `bundleId` zabezpečí, že link otvorí práve launcher (nie iná appka registrovaná
  na schému) a WDA počká, kým sa UI ustáli.
- Ak launcher ešte nebeží, `POST /url` s `bundleId` ho aktivuje a doručí deep link.

**Výhody:** nulová zmena WDA, funguje hneď.
**Nevýhody:** kontrakt („ako sa skladá URL") žije mimo WDA; klient musí poznať
schému aj bundleId; žiadna validácia, že sa projekt naozaj otvoril.

### Variant B — „Cold start" launcher + následný deep link

Ak potrebujeme launcher najprv istotne studeno naštartovať (napr. po reštarte
zariadenia), skombinujeme:

1. `POST /wda/apps/launchUnattached` `{ "bundleId": "eu.el-iv.mylauncher" }`
   — dostane launcher do popredia bez nutnosti aktívnej XCTest session.
2. `POST /url` `{ "url": "mylauncher://open?projectId=42", "bundleId": "eu.el-iv.mylauncher" }`
   — doručí konkrétny projekt.

**Výhody:** deterministické poradie; oddeľuje „spusti appku" od „otvor projekt".
**Nevýhody:** dve volania; orchestráciu rieši klient.

### Variant C — Nový dedikovaný endpoint `POST /wda/project/open` (odporúčané)

Zabalí logiku variantov A/B do jedného, sémanticky jasného volania a presunie
zostavovanie deep linku a validáciu na stranu WDA.

```http
POST /wda/project/open HTTP/1.1
Content-Type: application/json

{
  "bundleId":   "eu.el-iv.mylauncher",   // povinné: cieľová launcher appka
  "projectId":  "42",                     // povinné (alebo "deepLink" nižšie)
  "deepLink":   null,                     // voliteľné: úplný URL; ak je zadaný, má prednosť pred projectId
  "urlTemplate":"mylauncher://open?projectId={projectId}", // voliteľné override šablóny
  "coldStart":  true,                     // ak true, najprv launchUnattached
  "idleTimeoutMs": 5000                   // voliteľné čakanie na ustálenie UI
}
```

Správanie handlera (pseudo):

```
1. validuj vstup (bundleId povinné; aspoň jedno z {projectId, deepLink})
2. ak coldStart -> FBUnattachedAppLauncher launchAppWithBundleId:bundleId
3. url = deepLink ?? render(urlTemplate, projectId)   // default šablóna konfigurovateľná
4. XCUIDevice.sharedDevice fb_openUrl:url withApplication:bundleId
5. ak idleTimeoutMs > 0 -> fb_waitUntilStableWithTimeout
6. vráť OK / štruktúrovanú chybu
```

**Výhody:** jedno volanie, jasná sémantika „otvor projekt", validácia na serveri,
klient nemusí poznať tvar deep linku (stačí `projectId`).
**Nevýhody:** vyžaduje zmenu WDA (nová route + handler + test).

## 4. Odporúčanie

- **Krátkodobo:** Variant A — nasadiť hneď cez existujúci `POST /url` s `bundleId`.
- **Cieľovo:** Variant C — pridať `POST /wda/project/open` ako tenký wrapper nad
  `fb_openUrl:withApplication:` a `FBUnattachedAppLauncher`, aby bola sémantika
  „otvorenie projektu" prvotriednou súčasťou API a kontrakt deep linku žil na
  jednom mieste.

Varianty nie sú v konflikte: C interne používa tie isté primitíva ako A/B, takže
migrácia je bezbolestná.

## 5. Náčrt implementácie Variantu C

Nová route by logicky patrila do `FBCustomCommands.m` (vedľa
`launchUnattached`), keďže nemusí byť viazaná na session:

```objc
// FBCustomCommands.m – routes
[[FBRoute POST:@"/wda/project/open"].withoutSession
    respondWithTarget:self action:@selector(handleOpenProject:)],

// handler
+ (id<FBResponsePayload>)handleOpenProject:(FBRouteRequest *)request
{
  NSString *bundleId  = request.arguments[@"bundleId"];
  NSString *projectId = request.arguments[@"projectId"];
  NSString *deepLink  = request.arguments[@"deepLink"];
  NSString *template  = request.arguments[@"urlTemplate"] ?: kDefaultProjectURLTemplate;
  BOOL coldStart      = [request.arguments[@"coldStart"] boolValue];
  NSNumber *idleMs    = request.arguments[@"idleTimeoutMs"];

  if (bundleId.length == 0) {
    return FBResponseWithStatus([FBCommandStatus
        invalidArgumentErrorWithMessage:@"'bundleId' is required" traceback:nil]);
  }
  NSString *url = deepLink.length > 0
      ? deepLink
      : [template stringByReplacingOccurrencesOfString:@"{projectId}"
                                            withString:(projectId ?: @"")];
  if (url.length == 0) {
    return FBResponseWithStatus([FBCommandStatus
        invalidArgumentErrorWithMessage:@"Provide 'deepLink' or 'projectId'" traceback:nil]);
  }

  if (coldStart) {
    [FBUnattachedAppLauncher launchAppWithBundleId:bundleId];
  }

  NSError *error;
  if (![XCUIDevice.sharedDevice fb_openUrl:url withApplication:bundleId error:&error]) {
    return FBResponseWithUnknownError(error);
  }
  if (idleMs.doubleValue > 0) {
    XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundleId];
    [app fb_waitUntilStableWithTimeout:FBMillisToSeconds(idleMs.doubleValue)];
  }
  return FBResponseWithOK();
}
```

Poznámka: `kDefaultProjectURLTemplate` (napr. `mylauncher://open?projectId={projectId}`)
navrhujeme držať konfigurovateľný — buď konštanta, alebo cez `POST /appium/settings`.

## 6. Tok (sekvenčný diagram)

```
Backend / CI            WDA HTTP server            iOS zariadenie (launcher)
     |                        |                             |
     |  POST /wda/project/open|                             |
     |----------------------->|                             |
     |                        | (coldStart) launchUnattached|
     |                        |---------------------------->|  launcher do popredia
     |                        | fb_openUrl:withApplication: |
     |                        |---------------------------->|  deep link -> projekt 42
     |                        | waitUntilStable (idleTimeout)|
     |        200 OK          |<----------------------------|
     |<-----------------------|                             |
```

## 7. Chybové stavy

| Situácia | Odpoveď |
|---|---|
| Chýba `bundleId` | `invalidArgument` |
| Chýba `projectId` aj `deepLink` | `invalidArgument` |
| Neplatná/nepodporovaná URL schéma | `unknownError` (z `fb_openUrl:` — „does not support"/„Cannot open") |
| Launcher nie je nainštalovaný | `unknownError` (LSApplicationWorkspace zlyhá) |
| UI sa neustálilo v `idleTimeoutMs` | OK (timeout je best-effort), zvážiť flag na tvrdé zlyhanie |

## 8. Bezpečnosť a prevádzka

- **Deep link ako vstup:** URL je efektívne príkaz pre launcher. `projectId`
  vkladáme do šablóny — treba URL-enkódovať hodnotu, aby sa nedali injektovať
  ďalšie query parametre. V náčrte doplniť `stringByAddingPercentEncoding…`.
- **Autorizácia:** WDA server sám o sebe nemá auth vrstvu; endpoint dedí rovnaký
  bezpečnostný model ako zvyšok WDA (dôveryhodná sieť / tunel). Neotvára novú
  útočnú plochu nad rámec už existujúceho `POST /url`.
- **Idempotencia:** opakované volanie s rovnakým `projectId` je bezpečné — len
  znovu otvorí ten istý projekt.

## 9. Predpoklady a otvorené otázky

Tento návrh stojí na predpokladoch, ktoré treba potvrdiť (pôvodné zadanie bolo
stručné):

1. **Čo je „launcher"?** Predpokladáme iOS/tvOS aplikáciu s vlastnou URL schémou
   alebo universal linkom. Ak ide o inú entitu (napr. macOS launcher cez
   Mac2Driver), API sa upraví.
2. **Čo je „projekt"?** Predpokladáme entitu adresovateľnú `projectId` v deep
   linku. Ak projekt vyžaduje viac parametrov (workspace, používateľ…), rozšíri
   sa payload / šablóna.
3. **Chceme nový endpoint, alebo stačí dokumentovať existujúci `POST /url`?**
   Variant A funguje bez zmeny kódu; Variant C je komfort a čistejší kontrakt.
4. **Kde má žiť šablóna deep linku** — v klientovi, ako konštanta vo WDA, alebo
   v `settings`?

Po potvrdení bodov 1–4 vieme Variant C dotiahnuť do plnej implementácie vrátane
testu v `WebDriverAgentTests` a mocha integračného testu v `test/`.
