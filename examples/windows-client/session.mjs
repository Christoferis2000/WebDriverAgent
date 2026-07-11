// Spolocna logika klienta pre WebDriverAgent (WDA).
//
// Tento modul zostavuje WebdriverIO options a spusta session. Pouzivaju ho:
//   - test.mjs  (jednoduchy env-based klient)
//   - menu.mjs  (interaktivny vyber "projektu" / profilu)
//
// BEZPECNOST (zhrnutie, overene v zdrojaku WDA):
//   - Automatizacia bezi NATIVNE na zariadeni (XCTest.framework).
//   - Realne zariadenie: klient ide VZDY cez USB (usbmux) na 127.0.0.1:<wdaLocalPort>,
//     nikdy nepotrebuje WiFi IP zariadenia. To je primarna izolacia.
//   - WDA na zariadeni sa ale BEZ nastavenia bindne na vsetky rozhrania (0.0.0.0),
//     vratane WiFi (port 8100), a nema ziadnu autentifikaciu ani TLS.
//   - wdaBindingIP=127.0.0.1 -> USE_IP -> WDA sa bindne len na loopback. V kode WDA
//     to funguje aj na realnom zariadeni; pozor, oficialne XCUITest docs ho vsak
//     znacia ako "only relevant for simulators", takze efekt moze zavisiet od verzie
//     drivera. Ber ho ako DOPLNKOVY zamok proti WiFi expozicii + over si to.

import { remote } from 'webdriverio';

/**
 * Zostavi WebdriverIO options z konfiguracie profilu.
 * @param {object} config { APPIUM_URL, CLOUD_USER, CLOUD_KEY, DEVICE_NAME,
 *                          PLATFORM_VERSION, BUNDLE_ID, WDA_BINDING_IP }
 */
export function buildOptions(config) {
  const {
    APPIUM_URL = 'http://127.0.0.1:4723',
    CLOUD_USER = '',
    CLOUD_KEY = '',
    DEVICE_NAME = 'iPhone 15',
    PLATFORM_VERSION = '17.0',
    BUNDLE_ID = 'com.apple.Preferences',
    WDA_BINDING_IP = '127.0.0.1',
  } = config;

  const isCloud = Boolean(CLOUD_USER && CLOUD_KEY);

  const capabilities = {
    platformName: 'iOS',
    'appium:automationName': 'XCUITest',
    'appium:deviceName': DEVICE_NAME,
    'appium:platformVersion': PLATFORM_VERSION,
    'appium:bundleId': BUNDLE_ID,
    // Nechaj Appium/farmu spravovat WDA za nas:
    'appium:autoLaunch': true,
  };

  // Doplnkovy zamok: drz WDA na zariadeni viazane len na loopback. Pre cloud farmu
  // WDA spravuje farma, takze tam to nenastavujeme.
  if (WDA_BINDING_IP && !isCloud) {
    capabilities['appium:wdaBindingIP'] = WDA_BINDING_IP;
  }

  // Rozparsovanie APPIUM_URL na host/port/path/protocol pre WebdriverIO.
  const url = new URL(APPIUM_URL);
  const options = {
    protocol: url.protocol.replace(':', ''),
    hostname: url.hostname,
    port: url.port ? Number(url.port) : url.protocol === 'https:' ? 443 : 80,
    path: url.pathname && url.pathname !== '/' ? url.pathname : '/',
    capabilities,
    logLevel: 'warn',
  };

  // Cloud farma (BrowserStack/Sauce styl).
  if (isCloud) {
    options.user = CLOUD_USER;
    options.key = CLOUD_KEY;
    capabilities['appium:username'] = CLOUD_USER;
    capabilities['appium:accessKey'] = CLOUD_KEY;
  }

  return { options, capabilities, resolved: {
    APPIUM_URL, DEVICE_NAME, PLATFORM_VERSION, BUNDLE_ID, isCloud,
  } };
}

/**
 * Spusti XCUITest session, vypise ukazku page source a korektne ju ukonci.
 * @param {object} config konfiguracia profilu (viz buildOptions)
 */
export async function runSession(config) {
  const { options, capabilities, resolved } = buildOptions(config);

  console.log(`[i] Pripajam sa na WDA/Appium: ${resolved.APPIUM_URL}`);
  console.log(
    `[i] Zariadenie: ${resolved.DEVICE_NAME} (iOS ${resolved.PLATFORM_VERSION}), appka: ${resolved.BUNDLE_ID}`
  );
  if (capabilities['appium:wdaBindingIP']) {
    console.log(
      `[i] Bezpecnost: wdaBindingIP=${capabilities['appium:wdaBindingIP']} (doplnkovy zamok proti WiFi; realne zariadenie ide aj tak cez USB)`
    );
  }

  const driver = await remote(options);
  try {
    console.log('[✓] Session vytvorena. WDA zije!');

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

/** Spolocny vypis tipov pri chybe. */
export function printFailureHints(err) {
  console.error('\n[x] Nepodarilo sa spustit session:');
  console.error(err?.message || err);
  console.error(
    '\nTipy:\n' +
      ' - Cesta B (Mac): bezi na Macu `appium`? Sedi APPIUM_URL a port 4723? Nebloknuje firewall?\n' +
      ' - Cesta A (cloud): su spravne CLOUD_USER/CLOUD_KEY a URL endpointu farmy?\n' +
      ' - Sedi DEVICE_NAME a PLATFORM_VERSION s dostupnym zariadenim/simulatorom?'
  );
}
