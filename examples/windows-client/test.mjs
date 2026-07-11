// Minimalny klient na vyskusanie WebDriverAgent (WDA) z Windows PC.
//
// Windows nevie WDA zbuildovat/spustit (vyzaduje macOS + Xcode). Tento skript
// je iba KLIENT: pripoji sa na Appium/WDA endpoint, ktory bezi bud v cloudovej
// device farme (Cesta A) alebo na Macu (Cesta B), vytvori XCUITest session a
// vypise page source, aby si videl, ze spojenie a automatizacia funguju.
//
// Spustenie:
//   1) npm install
//   2) nastav premenne prostredia (pozri .env.example) alebo uprav CONFIG nizsie
//   3) node test.mjs
//
// Pozn.: Tento subor zamerne NEnacitava .env automaticky (bez extra zavislosti).
// Premenne nastav v shelli, napr. v PowerShelli:
//   $env:APPIUM_URL = "http://192.168.1.50:4723"; node test.mjs

import { remote } from 'webdriverio';

// --- Konfiguracia z premennych prostredia (s rozumnymi defaultmi) ------------

const {
  // Plna URL Appium/WDA endpointu. Priklady:
  //   Mac v lokalnej sieti:   http://192.168.1.50:4723
  //   BrowserStack:           https://hub-cloud.browserstack.com/wd/hub
  APPIUM_URL = 'http://127.0.0.1:4723',

  // Cesta A (cloud) - prihlasovacie udaje farmy (nechaj prazdne pre Cestu B/lokal):
  CLOUD_USER = '',
  CLOUD_KEY = '',

  // Ake zariadenie/appku chceme. Pre simulator staci nazov + verzia iOS.
  DEVICE_NAME = 'iPhone 15',
  PLATFORM_VERSION = '17.0',

  // Co spustit. Ak nezadas appku, pouzije sa vstavana appka Settings (Nastavenia),
  // co je najspolahlivejsi sposob, ako overit, ze automatizacia funguje.
  BUNDLE_ID = 'com.apple.Preferences',
} = process.env;

// --- Zostavenie W3C capabilities pre XCUITest driver -------------------------

const capabilities = {
  platformName: 'iOS',
  'appium:automationName': 'XCUITest',
  'appium:deviceName': DEVICE_NAME,
  'appium:platformVersion': PLATFORM_VERSION,
  'appium:bundleId': BUNDLE_ID,
  // Nechaj Appium/farmu spravovat WDA za nas:
  'appium:autoLaunch': true,
};

// Rozparsovanie APPIUM_URL na host/port/path/protocol, ktore ocakava WebdriverIO.
const url = new URL(APPIUM_URL);
const options = {
  protocol: url.protocol.replace(':', ''),
  hostname: url.hostname,
  port: url.port ? Number(url.port) : url.protocol === 'https:' ? 443 : 80,
  path: url.pathname && url.pathname !== '/' ? url.pathname : '/',
  capabilities,
  logLevel: 'warn',
};

// Ak su zadane cloud udaje, pridame ich (BrowserStack/Sauce styl).
if (CLOUD_USER && CLOUD_KEY) {
  options.user = CLOUD_USER;
  options.key = CLOUD_KEY;
  capabilities['appium:username'] = CLOUD_USER;
  capabilities['appium:accessKey'] = CLOUD_KEY;
}

// --- Spustenie session -------------------------------------------------------

async function main() {
  console.log(`[i] Pripajam sa na WDA/Appium: ${APPIUM_URL}`);
  console.log(`[i] Zariadenie: ${DEVICE_NAME} (iOS ${PLATFORM_VERSION}), appka: ${BUNDLE_ID}`);

  const driver = await remote(options);
  try {
    console.log('[✓] Session vytvorena. WDA zije!');

    // Kratka pauza, nech sa appka nacita, a vypis casti page source.
    await driver.pause(2000);
    const source = await driver.getPageSource();
    console.log('[i] Ukazka page source (prvych 800 znakov):\n');
    console.log(source.slice(0, 800));

    console.log('\n[✓] Hotovo - automatizacia cez WebDriverAgent funguje.');
  } finally {
    await driver.deleteSession();
    console.log('[i] Session ukoncena.');
  }
}

main().catch((err) => {
  console.error('\n[x] Nepodarilo sa spustit session:');
  console.error(err?.message || err);
  console.error(
    '\nTipy:\n' +
      ' - Cesta B (Mac): bezi na Macu `appium`? Sedi APPIUM_URL a port 4723? Nebloknuje firewall?\n' +
      ' - Cesta A (cloud): su spravne CLOUD_USER/CLOUD_KEY a URL endpointu farmy?\n' +
      ' - Sedi DEVICE_NAME a PLATFORM_VERSION s dostupnym zariadenim/simulatorom?'
  );
  process.exitCode = 1;
});
