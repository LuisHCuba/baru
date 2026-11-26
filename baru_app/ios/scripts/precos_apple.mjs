#!/usr/bin/env node
// Preço de cada assinatura do Baru: o do Brasil e os equivalentes que a
// Apple calcula para os outros países (equalizations), e a disponibilidade
// em todos os países. Idempotente. Não envia nada para revisão.
const { api } = await import('/Users/luishcuba/claude/deixa/ios/scripts/asc.mjs');
const PRECOS = {
  'tech.lhcx.baru.mensal': '14.90', 'tech.lhcx.baru.anual': '118.80',
  'tech.lhcx.baru.familia.mensal': '24.90', 'tech.lhcx.baru.familia.anual': '229.00',
  'tech.lhcx.baru.familiamais.mensal': '34.90',
};
const todos = async (url) => { let out = [], inc = [], next = url; while (next) { const r = await api('GET', next); out = out.concat(r.data); inc = inc.concat(r.included || []); next = r.links?.next; } return { data: out, included: inc }; };
const grupo = (await todos('/v1/apps/6836622357/subscriptionGroups')).data.find((g) => g.attributes.referenceName === 'Planos do Baru');
const subs = (await todos(`/v1/subscriptionGroups/${grupo.id}/subscriptions`)).data;
const territorios = (await todos('/v1/territories?limit=200')).data.map((t) => t.id);
for (const s of subs) {
  const alvo = PRECOS[s.attributes.productId];
  // disponibilidade
  try {
    await api('POST', '/v1/subscriptionAvailabilities', { data: { type: 'subscriptionAvailabilities', attributes: { availableInNewTerritories: true }, relationships: { subscription: { data: { type: 'subscriptions', id: s.id } }, availableTerritories: { data: territorios.map((id) => ({ type: 'territories', id })) } } } });
    console.log(s.attributes.productId, 'disponível em', territorios.length, 'países');
  } catch (e) { console.log(s.attributes.productId, 'disponibilidade:', e.status); }
  // preço já definido?
  const atuais = await todos(`/v1/subscriptions/${s.id}/prices?include=territory&limit=200`);
  if (atuais.data.length >= territorios.length - 5) { console.log(s.attributes.productId, 'preços já definidos:', atuais.data.length); continue; }
  const pontos = (await todos(`/v1/subscriptions/${s.id}/pricePoints?filter[territory]=BRA&limit=200`)).data;
  const br = pontos.find((p) => Number(p.attributes.customerPrice).toFixed(2) === alvo);
  if (!br) { console.log(s.attributes.productId, 'SEM ponto de preço', alvo); continue; }
  const eq = (await todos(`/v1/subscriptionPricePoints/${br.id}/equalizations?include=territory&limit=200`));
  const lista = [{ id: br.id, terr: 'BRA' }, ...eq.data.map((p) => ({ id: p.id, terr: p.relationships?.territory?.data?.id }))];
  let ok = 0, erro = 0;
  for (const p of lista) {
    try {
      await api('POST', '/v1/subscriptionPrices', { data: { type: 'subscriptionPrices', attributes: { preserveCurrentPrice: false }, relationships: { subscription: { data: { type: 'subscriptions', id: s.id } }, subscriptionPricePoint: { data: { type: 'subscriptionPricePoints', id: p.id } } } } });
      ok++;
    } catch (e) { erro++; if (erro < 3) console.log('  erro', p.terr, e.status, String(e.message).slice(0, 160)); }
  }
  console.log(s.attributes.productId, 'R$', alvo, 'preços gravados:', ok, 'erros:', erro);
}
