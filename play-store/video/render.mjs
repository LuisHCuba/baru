// Fotografa scene.html quadro a quadro no Chromium e codifica com ffmpeg.
// Uso:
//   node render.mjs still v 1.2 4 9.5     → build/still_v_<t>.jpg (conferência)
//   node render.mjs full v                 → build/video_v.mp4 (sem áudio)
//   node render.mjs full h                 → build/video_h.mp4
import { createRequire } from 'module';
import { execSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); }
catch { ({ chromium } = require(path.join(execSync('npm root -g').toString().trim(), 'playwright'))); }

const FPS = 30, DUR = 37.5;
const [modo, f = 'v', ...tempos] = process.argv.slice(2);
const [W, H] = f === 'v' ? [1080, 1920] : [1920, 1080];
const build = path.join(aqui, 'build');
fs.mkdirSync(build, { recursive: true });
const WORDS = JSON.parse(fs.readFileSync(path.join(aqui, 'assets/vo/narracao.words.json'), 'utf8'));

const browser = await chromium.launch({ args: ['--font-render-hinting=none', '--allow-file-access-from-files', '--disable-gpu'] });
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
const page = await ctx.newPage();
page.on('pageerror', (e) => console.error('erro na cena:', e.message));
await page.addInitScript((w) => { window.WORDS = w; }, WORDS);
await page.goto(pathToFileURL(path.join(aqui, 'scene.html')).href + '?f=' + f);
await page.evaluate(() => window.__ready);

async function quadro(t) {
  await page.evaluate(async (t) => {
    window.render(t);
    // a troca de src do quadro do clipe precisa decodificar antes da foto
    await Promise.all([...document.images].filter((i) => !i.complete).map((i) => i.decode().catch(() => {})));
  }, t);
  return page.screenshot({ type: 'jpeg', quality: 95 });
}

if (modo === 'still') {
  for (const t of tempos) fs.writeFileSync(path.join(build, `still_${f}_${t}.jpg`), await quadro(+t));
} else {
  const saida = path.join(build, `video_${f}.mp4`);
  const ff = spawn('ffmpeg', ['-y', '-v', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', saida], { stdio: ['pipe', 'inherit', 'inherit'] });
  const total = Math.round(DUR * FPS);
  for (let i = 0; i < total; i++) {
    const buf = await quadro(i / FPS);
    if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r));
    if (i % 150 === 0) console.log(`${f}: ${i}/${total}`);
  }
  ff.stdin.end();
  await new Promise((r) => ff.on('close', r));
  console.log(saida);
}
await browser.close();
