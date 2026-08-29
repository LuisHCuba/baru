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

/* Nomes aceitos para a chave, em ordem. Existe mais de um porque o painel
   do Supabase hoje chama de "publishable key" e o nome da variavel varia
   conforme quem a cria — errar o nome fazia o build passar em silencio
   com o formulario escondido. */
const NOMES_CHAVE = [
  'SUPABASE_ANON_KEY',
  'SUPABASE_PUBLISHABLE_KEY',
  'SUPABASE_PUBLISHABLE_DEFAULT_KEY',
  'SUPABASE_KEY',
  'VITE_SUPABASE_ANON_KEY',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
];
const NOMES_URL = ['SUPABASE_URL', 'VITE_SUPABASE_URL', 'NEXT_PUBLIC_SUPABASE_URL'];

function doAmbiente(nomes) {
  for (const nome of nomes) {
    const valor = (process.env[nome] || '').trim();
    if (valor) return { nome, valor };
  }
  return null;
}

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

const achado = doAmbiente(NOMES_CHAVE);

if (!achado) {
  console.log(
    'Nenhuma chave do Supabase no ambiente.\n' +
    'Procurei por: ' + NOMES_CHAVE.join(', ') + '.\n' +
    'O site publica normalmente, mas o formulario da lista de espera fica\n' +
    'escondido. Defina a variavel em Site settings -> Environment variables\n' +
    'e dispare um deploy novo (mudar a variavel sozinha nao reconstroi).'
  );
  process.exit(0);
}

const chave = achado.valor;
console.log(`Chave encontrada em ${achado.nome}.`);

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

let saida = html.replace(ALVO, `anonKey: ${JSON.stringify(chave)}`);

/* A URL tambem pode vir do ambiente. O padrao no arquivo e o projeto do
   .env.example, entao isto so importa se um dia o projeto mudar. */
const urlAmbiente = doAmbiente(NOMES_URL);
if (urlAmbiente) {
  const url = urlAmbiente.valor.replace(/\/+$/, '');
  saida = saida.replace(/url: "[^"]*"/, `url: ${JSON.stringify(url)}`);
  console.log(`URL sobrescrita por ${urlAmbiente.nome}: ${url}`);
}

fs.writeFileSync(ARQUIVO, saida);
console.log('Chave injetada. Formulario da lista de espera ativo.');
