#!/usr/bin/env node
// Cria (ou completa) o grupo "Planos do Baru" e as 5 assinaturas na App Store
// Connect. Idempotente: o que já existe é reaproveitado. Não envia nada para
// revisão. Uso: ../../deixa/ios/scripts/with-asc-env.sh node scripts/planos_apple.mjs
const { api } = await import('/Users/luishcuba/claude/deixa/ios/scripts/asc.mjs');
const APP = '6836622357';

// Preços: os do site (termos: "o mesmo preço em todo lugar").
const PLANOS = [
  { id: 'tech.lhcx.baru.familiamais.mensal', ref: 'Família+ mensal', periodo: 'ONE_MONTH', nivel: 1, preco: '34.9',
    pt: ['Baru Família+', 'Até 10 pessoas do laço, renovação mensal'], en: ['Baru Family+', 'Up to 10 people in the bond, monthly'], es: ['Baru Familia+', 'Hasta 10 personas del lazo, mensual'] },
  { id: 'tech.lhcx.baru.familia.anual', ref: 'Família anual', periodo: 'ONE_YEAR', nivel: 2, preco: '229.0',
    pt: ['Baru Família anual', 'Até 6 pessoas do laço, renovação anual'], en: ['Baru Family yearly', 'Up to 6 people in the bond, yearly'], es: ['Baru Familia anual', 'Hasta 6 personas del lazo, anual'] },
  { id: 'tech.lhcx.baru.familia.mensal', ref: 'Família mensal', periodo: 'ONE_MONTH', nivel: 2, preco: '24.9',
    pt: ['Baru Família', 'Até 6 pessoas do laço, renovação mensal'], en: ['Baru Family', 'Up to 6 people in the bond, monthly'], es: ['Baru Familia', 'Hasta 6 personas del lazo, mensual'] },
  { id: 'tech.lhcx.baru.anual', ref: 'Individual anual', periodo: 'ONE_YEAR', nivel: 3, preco: '118.8',
    pt: ['Baru Individual anual', 'Tudo do Baru para você, renovação anual'], en: ['Baru Individual yearly', 'All of Baru for you, yearly'], es: ['Baru Individual anual', 'Todo Baru para ti, anual'] },
  { id: 'tech.lhcx.baru.mensal', ref: 'Individual mensal', periodo: 'ONE_MONTH', nivel: 3, preco: '14.9',
    pt: ['Baru Individual', 'Tudo do Baru para você, renovação mensal'], en: ['Baru Individual', 'All of Baru for you, monthly'], es: ['Baru Individual', 'Todo Baru para ti, mensual'] },
];
const LOCAIS = { pt: 'pt-BR', en: 'en-US', es: 'es-MX' };
const NOTA = 'Subscription that unlocks Baru after the 7-day free trial. Settings > Your account > Subscribe to Baru (also shown when the trial ends). Family plans cover people in the bond the buyer administers (Bonds tab).';

const todos = async (url) => { let out = [], next = url; while (next) { const r = await api('GET', next); out = out.concat(r.data); next = r.links?.next; } return out; };

// 1. grupo
let grupo = (await todos(`/v1/apps/${APP}/subscriptionGroups`)).find((g) => g.attributes.referenceName === 'Planos do Baru');
if (!grupo) {
  grupo = (await api('POST', '/v1/subscriptionGroups', { data: { type: 'subscriptionGroups', attributes: { referenceName: 'Planos do Baru' }, relationships: { app: { data: { type: 'apps', id: APP } } } } })).data;
  console.log('grupo criado', grupo.id);
} else console.log('grupo já existe', grupo.id);
const glocs = await todos(`/v1/subscriptionGroups/${grupo.id}/subscriptionGroupLocalizations`);
for (const [k, loc] of Object.entries(LOCAIS)) {
  if (glocs.some((l) => l.attributes.locale === loc)) continue;
  await api('POST', '/v1/subscriptionGroupLocalizations', { data: { type: 'subscriptionGroupLocalizations', attributes: { locale: loc, name: { pt: 'Planos do Baru', en: 'Baru plans', es: 'Planes de Baru' }[k], customAppName: 'Baru' }, relationships: { subscriptionGroup: { data: { type: 'subscriptionGroups', id: grupo.id } } } } });
  console.log('nome do grupo', loc);
}

// 2. assinaturas
const existentes = await todos(`/v1/subscriptionGroups/${grupo.id}/subscriptions`);
for (const p of PLANOS) {
  let s = existentes.find((x) => x.attributes.productId === p.id);
  if (!s) {
    s = (await api('POST', '/v1/subscriptions', { data: { type: 'subscriptions', attributes: { name: p.ref, productId: p.id, subscriptionPeriod: p.periodo, familySharable: false, groupLevel: p.nivel, reviewNote: NOTA }, relationships: { group: { data: { type: 'subscriptionGroups', id: grupo.id } } } } })).data;
    console.log('criado', p.id, s.id);
  } else console.log('já existe', p.id, s.attributes.state);
  const locs = await todos(`/v1/subscriptions/${s.id}/subscriptionLocalizations`);
  for (const [k, loc] of Object.entries(LOCAIS)) {
    if (locs.some((l) => l.attributes.locale === loc)) continue;
    await api('POST', '/v1/subscriptionLocalizations', { data: { type: 'subscriptionLocalizations', attributes: { locale: loc, name: p[k][0], description: p[k][1] }, relationships: { subscription: { data: { type: 'subscriptions', id: s.id } } } } });
  }
  p.sid = s.id;
}
console.log(JSON.stringify(PLANOS.map((p) => [p.id, p.sid])));
