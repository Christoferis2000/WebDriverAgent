// Interaktivne menu na vyber "projektu" (ulozeneho profilu) a spustenie session.
//
// Po spusteni zobrazi cislovany zoznam profilov z projects.json, ty vyberies
// cislo a spusti sa session voci danemu endpointu.
//
// Spustenie:
//   node menu.mjs            -> interaktivny vyber
//   node menu.mjs 2          -> rovno vyber projekt cislo 2 (neinteraktivne)
//   run.cmd                  -> to iste na Windowse (dvojklik / z cmd)
//
// Cloud kluce: ak profil ma prazdne CLOUD_USER/CLOUD_KEY, pouziju sa env premenne
// CLOUD_USER/CLOUD_KEY (ak su nastavene), inak sa na ne interaktivne opytame.

import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';
import { runSession, printFailureHints } from './session.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PROJECTS_FILE = path.join(HERE, 'projects.json');

async function loadProjects() {
  const raw = await readFile(PROJECTS_FILE, 'utf8');
  const data = JSON.parse(raw);
  if (!Array.isArray(data.projects) || data.projects.length === 0) {
    throw new Error('projects.json neobsahuje ziadne projekty.');
  }
  return data.projects;
}

function printMenu(projects) {
  console.log('\n=== WebDriverAgent – vyber projektu ===\n');
  projects.forEach((p, i) => {
    console.log(`  ${i + 1}) ${p.name}`);
    if (p.description) {
      console.log(`     ${p.description}`);
    }
  });
  console.log('');
}

async function chooseIndex(projects, argChoice) {
  // Neinteraktivny vyber cez argument (napr. `node menu.mjs 2`).
  if (argChoice !== undefined) {
    const n = Number(argChoice);
    if (!Number.isInteger(n) || n < 1 || n > projects.length) {
      throw new Error(`Neplatny vyber "${argChoice}". Zadaj cislo 1..${projects.length}.`);
    }
    return n - 1;
  }

  // Interaktivny vyber.
  printMenu(projects);
  const rl = readline.createInterface({ input, output });
  try {
    while (true) {
      const answer = (await rl.question(`Vyber projekt (1..${projects.length}), q = koniec: `)).trim();
      if (answer.toLowerCase() === 'q') {
        return -1;
      }
      const n = Number(answer);
      if (Number.isInteger(n) && n >= 1 && n <= projects.length) {
        return n - 1;
      }
      console.log(`  Neplatny vstup. Zadaj cislo 1..${projects.length} alebo q.`);
    }
  } finally {
    rl.close();
  }
}

async function ensureCloudCreds(project) {
  // Iba pre cloud profil (ma kluce CLOUD_USER/CLOUD_KEY v definicii).
  const needsCloud = 'CLOUD_USER' in project || 'CLOUD_KEY' in project;
  if (!needsCloud) {
    return project;
  }

  let user = project.CLOUD_USER || process.env.CLOUD_USER || '';
  let key = project.CLOUD_KEY || process.env.CLOUD_KEY || '';

  if (!user || !key) {
    const rl = readline.createInterface({ input, output });
    try {
      if (!user) {
        user = (await rl.question('Cloud CLOUD_USER: ')).trim();
      }
      if (!key) {
        key = (await rl.question('Cloud CLOUD_KEY: ')).trim();
      }
    } finally {
      rl.close();
    }
  }

  return { ...project, CLOUD_USER: user, CLOUD_KEY: key };
}

async function main() {
  const projects = await loadProjects();
  const argChoice = process.argv[2];

  const idx = await chooseIndex(projects, argChoice);
  if (idx < 0) {
    console.log('Koniec.');
    return;
  }

  let project = projects[idx];
  console.log(`\n[i] Vybrany projekt: ${project.name}`);
  project = await ensureCloudCreds(project);

  await runSession(project);
}

main().catch((err) => {
  printFailureHints(err);
  process.exitCode = 1;
});
