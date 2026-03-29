#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

// ============================================================
// Pulsation Indoor Festival 2026 - Apple Wallet Pass Generator
// ============================================================
//
// Pouzitie:
//   1. Vloz certifikaty do priecinka ./certs/:
//      - signerCert.pem   (Pass Type ID certifikat)
//      - signerKey.pem    (privatny kluc)
//      - wwdr.pem         (Apple WWDR certifikat)
//
//   2. Uprav PASS_TYPE_ID a TEAM_ID nizsie
//
//   3. Spusti: node generate-passes.js
//
//   4. Vysledok: ticket_1.pkpass, ticket_2.pkpass
// ============================================================

const PASS_TYPE_ID = 'pass.com.example.pulsation'; // Zmen na svoj Pass Type ID
const TEAM_ID = 'XXXXXXXXXX'; // Zmen na svoj Apple Team ID

const CERTS_DIR = path.join(__dirname, 'certs');
const OUTPUT_DIR = __dirname;

const tickets = [
  {
    serialNumber: 'PULSATION-2026-001',
    barcode: '3937479925817',
    outputFile: 'ticket_1.pkpass',
  },
  {
    serialNumber: 'PULSATION-2026-002',
    barcode: '3937555449688',
    outputFile: 'ticket_2.pkpass',
  },
];

function createPassJson(ticket) {
  return {
    formatVersion: 1,
    passTypeIdentifier: PASS_TYPE_ID,
    teamIdentifier: TEAM_ID,
    serialNumber: ticket.serialNumber,
    organizationName: 'Comitas s.r.o.',
    description: 'Pulsation Indoor Festival 2026',
    foregroundColor: 'rgb(255, 255, 255)',
    backgroundColor: 'rgb(30, 30, 30)',
    labelColor: 'rgb(180, 180, 180)',
    eventTicket: {
      headerFields: [
        {
          key: 'date',
          label: 'DATUM',
          value: '28. 3. 2026',
        },
      ],
      primaryFields: [
        {
          key: 'event',
          label: 'UDALOST',
          value: 'Pulsation Indoor Festival 2026',
        },
      ],
      secondaryFields: [
        {
          key: 'venue',
          label: 'MIESTO',
          value: 'A4 Studio',
        },
        {
          key: 'ticket-type',
          label: 'TYP',
          value: 'One-day Ticket / SOBOTA',
        },
      ],
      auxiliaryFields: [
        {
          key: 'price',
          label: 'CENA',
          value: '35 €',
        },
        {
          key: 'category',
          label: 'KATEGORIA',
          value: 'LAST CHANCE',
        },
      ],
      backFields: [
        {
          key: 'address',
          label: 'ADRESA',
          value: 'Trnavska cesta 39, 831 04 Bratislava',
        },
        {
          key: 'organizer',
          label: 'ORGANIZATOR',
          value: 'Comitas s.r.o.\nLermontovova 911/3, 811 05 Bratislava\nICO: 52953963, DIC: 2121269557',
        },
        {
          key: 'support',
          label: 'ZAKAZNICKA PODPORA',
          value: 'www.goout.net/sk/casto-kladene-otazky\n+421 232 18 00 18\ninfo@goout.sk',
        },
      ],
    },
    barcodes: [
      {
        format: 'PKBarcodeFormatQR',
        message: ticket.barcode,
        messageEncoding: 'iso-8859-1',
      },
    ],
    barcode: {
      format: 'PKBarcodeFormatQR',
      message: ticket.barcode,
      messageEncoding: 'iso-8859-1',
    },
    relevantDate: '2026-03-28T18:00+02:00',
    locations: [
      {
        latitude: 48.1565,
        longitude: 17.1372,
        relevantText: 'Pulsation Indoor Festival - A4 Studio',
      },
    ],
  };
}

function sha1(filePath) {
  const data = fs.readFileSync(filePath);
  return crypto.createHash('sha1').update(data).digest('hex');
}

function createManifest(passDir) {
  const manifest = {};
  const files = fs.readdirSync(passDir).filter((f) => f !== 'manifest.json' && f !== 'signature');
  for (const file of files) {
    manifest[file] = sha1(path.join(passDir, file));
  }
  return manifest;
}

function generatePass(ticket) {
  const passDir = path.join(OUTPUT_DIR, `tmp_${ticket.serialNumber}`);

  // Vytvor temp priecinok
  if (fs.existsSync(passDir)) fs.rmSync(passDir, { recursive: true });
  fs.mkdirSync(passDir, { recursive: true });

  // Zapis pass.json
  const passJson = createPassJson(ticket);
  fs.writeFileSync(path.join(passDir, 'pass.json'), JSON.stringify(passJson, null, 2));

  // Skopiruj ikony ak existuju
  for (const icon of ['icon.png', 'icon@2x.png', 'logo.png', 'logo@2x.png']) {
    const src = path.join(__dirname, 'assets', icon);
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, path.join(passDir, icon));
    }
  }

  // Ak neexistuju ikony, vytvor placeholder
  if (!fs.existsSync(path.join(passDir, 'icon.png'))) {
    console.warn(`  VAROVANIE: Chyba icon.png v ./assets/ - pass nebude validny bez ikon`);
    console.warn(`  Pridaj minimalne icon.png (29x29) a icon@2x.png (58x58)`);
  }

  // Vytvor manifest.json
  const manifest = createManifest(passDir);
  fs.writeFileSync(path.join(passDir, 'manifest.json'), JSON.stringify(manifest, null, 2));

  // Podpis
  const signerCert = path.join(CERTS_DIR, 'signerCert.pem');
  const signerKey = path.join(CERTS_DIR, 'signerKey.pem');
  const wwdr = path.join(CERTS_DIR, 'wwdr.pem');

  if (fs.existsSync(signerCert) && fs.existsSync(signerKey) && fs.existsSync(wwdr)) {
    try {
      execSync(
        `openssl smime -sign -signer "${signerCert}" -inkey "${signerKey}" ` +
          `-certfile "${wwdr}" -in "${path.join(passDir, 'manifest.json')}" ` +
          `-out "${path.join(passDir, 'signature')}" -outform DER -binary`
      );
      console.log(`  Podpis vytvoreny.`);
    } catch (e) {
      console.error(`  CHYBA pri podpisovani: ${e.message}`);
      return;
    }
  } else {
    console.warn(`  VAROVANIE: Certifikaty nenajdene v ./certs/`);
    console.warn(`  Pass bude vytvoreny BEZ podpisu (nebude fungovat v Apple Wallet)`);
  }

  // Zabal do .pkpass (ZIP)
  const outputPath = path.join(OUTPUT_DIR, ticket.outputFile);
  if (fs.existsSync(outputPath)) fs.unlinkSync(outputPath);

  try {
    const files = fs.readdirSync(passDir).join(' ');
    execSync(`cd "${passDir}" && zip -q "${outputPath}" ${files}`);
    console.log(`  Vytvoreny: ${ticket.outputFile}`);
  } catch (e) {
    console.error(`  CHYBA pri vytvarani ZIP: ${e.message}`);
    console.error(`  Skus nainstalovat zip: apt install zip / brew install zip`);
  }

  // Uprac temp
  fs.rmSync(passDir, { recursive: true });
}

// === MAIN ===
console.log('=== Pulsation Indoor Festival 2026 - Wallet Pass Generator ===\n');

for (const ticket of tickets) {
  console.log(`Generujem: ${ticket.outputFile} (${ticket.barcode})`);
  generatePass(ticket);
  console.log('');
}

console.log('Hotovo!');
console.log('\nAk pasy nie su podpisane, potrebujes:');
console.log('  1. Apple Developer ucet (https://developer.apple.com)');
console.log('  2. Vytvorit Pass Type ID v Certificates, Identifiers & Profiles');
console.log('  3. Exportovat certifikat a kluc do ./certs/');
console.log('  4. Stiahnut Apple WWDR certifikat do ./certs/wwdr.pem');
