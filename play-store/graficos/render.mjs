// Fotografa peca.html no Chromium e grava as peças da ficha da Google Play.
// Uso: node render.mjs [pt en es]   → ../loja/<lang>/...
import { createRequire } from 'module';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); }
catch { ({ chromium } = require(path.join(execSync('npm root -g').toString().trim(), 'playwright'))); }

const langs = process.argv.slice(2).length ? process.argv.slice(2) : ['pt', 'en', 'es'];
const browser = await chromium.launch({ args: ['--font-render-hinting=none', '--allow-file-access-from-files'] });

async function foto(query, w, h, destino, tipo = 'png') {
  const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  await page.goto(pathToFileURL(path.join(aqui, 'peca.html')).href + '?' + query);
  await page.waitForFunction(() => window.__pronto === true);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(150);
  fs.mkdirSync(path.dirname(destino), { recursive: true });
  // PNG sem alfa: a loja recusa transparência nas capturas e no destaque.
  await page.screenshot({ path: destino, type: tipo, omitBackground: false, ...(tipo === 'jpeg' ? { quality: 92 } : {}) });
  await ctx.close();
  console.log(destino);
}

for (const lang of langs) {
  const pasta = path.join(aqui, '..', 'loja', lang);
  for (let n = 1; n <= 8; n++) await foto(`peca=tela&n=${n}&lang=${lang}`, 1080, 1920, path.join(pasta, `captura-${n}.png`));
  await foto(`peca=destaque&lang=${lang}`, 1024, 500, path.join(pasta, 'destaque-1024x500.png'));
}
await foto('peca=og&lang=pt', 1200, 630, path.join(aqui, '..', 'loja', 'og-1200x630.png'));
// capas do comercial: a vertical vai para a página do site, a horizontal é a miniatura do YouTube
await foto('peca=capaV&lang=pt', 1080, 1920, path.join(aqui, '..', 'video', 'saida', 'capa-vertical-1080x1920.png'));
await foto('peca=capaH&lang=pt', 1920, 1080, path.join(aqui, '..', 'video', 'saida', 'capa-horizontal-1920x1080.png'));
await browser.close();
