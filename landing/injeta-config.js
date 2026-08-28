#!/usr/bin/env node
/**
 * Injeta a chave publicável do Supabase no HTML antes de publicar.
 *
 * A chave vive numa variável de ambiente do Netlify (Site settings ->
 * Environment variables -> SUPABASE_ANON_KEY), nunca no repositório.
 * Sem ela o formulário da lista de espera simplesmente não aparece e a
 * página mostra só o "em breve" das lojas.
 *
 * Rode local com:  SUPABASE_ANON_KEY=... node landing/injeta-config.js
 */
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const ARQUIVO = path.join(__dirname, 'index.html');
const ALVO = 'anonKey: ""';

/** Recusa chave secreta. Publicar uma service_role é vazamento total. */
function ehSegura(chave) {
  if (chave.startsWith('sb_secret_')) return { ok: false, motivo: 'e uma chave secreta (sb_secret_)' };
  if (chave.startsWith('sb_publishable_')) return { ok: true };
  if (chave.startsWith('eyJ')) {
    try {
      const payload = JSON.parse(
        Buffer.from(chave.split('.')[1], 'base64url').toString('utf8')
      );
      if (payload.role === 'service_role') {
        return { ok: false, motivo: 'e a service_role, que da acesso total ao banco' };
      }
      if (payload.role && payload.role !== 'anon') {
        return { ok: false, motivo: `tem role "${payload.role}", esperado "anon"` };
      }
      return { ok: true };
    } catch {
      return { ok: false, motivo: 'parece um JWT mas nao consegui ler o payload' };
    }
  }
  return { ok: false, motivo: 'nao parece uma chave do Supabase' };
}

const chave = (process.env.SUPABASE_ANON_KEY || '').trim();

if (!chave) {
  console.log(
    'SUPABASE_ANON_KEY nao definida.\n' +
    'O site publica normalmente, mas o formulario da lista de espera fica\n' +
    'escondido. Defina a variavel em Site settings -> Environment variables.'
  );
  process.exit(0);
}

const veredito = ehSegura(chave);
if (!veredito.ok) {
  console.error(
    `SUPABASE_ANON_KEY recusada: ${veredito.motivo}.\n` +
    'Use a chave publishable/anon (Dashboard -> Settings -> API).'
  );
  process.exit(1);
}

const html = fs.readFileSync(ARQUIVO, 'utf8');
if (!html.includes(ALVO)) {
  console.error(
    `Nao encontrei ${ALVO} em landing/index.html.\n` +
    'Sem esse ponto de injecao a chave nao entra e o formulario fica\n' +
    'escondido sem ninguem perceber — por isso o build para aqui.'
  );
  process.exit(1);
}

fs.writeFileSync(ARQUIVO, html.replace(ALVO, `anonKey: ${JSON.stringify(chave)}`));
console.log('Chave injetada. Formulario da lista de espera ativo.');
