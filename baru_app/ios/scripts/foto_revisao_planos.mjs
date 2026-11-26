#!/usr/bin/env node
// Envia a foto da tela de compra (docs/apple/revisao_assinatura.png) como
// foto de revisão de cada assinatura do Baru. Idempotente.
import fs from 'node:fs';
import crypto from 'node:crypto';
const { api } = await import('/Users/luishcuba/claude/deixa/ios/scripts/asc.mjs');
const ARQ = '/Users/luishcuba/claude/baru/docs/apple/revisao_assinatura.png';
const bytes = fs.readFileSync(ARQ);
const md5 = crypto.createHash('md5').update(bytes).digest('hex');
const grupo = (await api('GET', '/v1/apps/6836622357/subscriptionGroups')).data.find((g) => g.attributes.referenceName === 'Planos do Baru');
const subs = (await api('GET', `/v1/subscriptionGroups/${grupo.id}/subscriptions?limit=50`)).data;
for (const s of subs) {
  const atual = await api('GET', `/v1/subscriptions/${s.id}/appStoreReviewScreenshot`).catch(() => null);
  if (atual?.data?.attributes?.assetDeliveryState?.state === 'COMPLETE') { console.log(s.attributes.productId, 'já tem foto'); continue; }
  if (atual?.data) await api('DELETE', `/v1/subscriptionAppStoreReviewScreenshots/${atual.data.id}`).catch(() => {});
  const r = (await api('POST', '/v1/subscriptionAppStoreReviewScreenshots', { data: { type: 'subscriptionAppStoreReviewScreenshots', attributes: { fileName: 'revisao_assinatura.png', fileSize: bytes.length }, relationships: { subscription: { data: { type: 'subscriptions', id: s.id } } } } })).data;
  for (const op of r.attributes.uploadOperations) {
    const parte = bytes.subarray(op.offset, op.offset + op.length);
    const h = Object.fromEntries(op.requestHeaders.map((x) => [x.name, x.value]));
    const up = await fetch(op.url, { method: op.method, headers: h, body: parte });
    if (!up.ok) throw new Error(`upload ${up.status}`);
  }
  await api('PATCH', `/v1/subscriptionAppStoreReviewScreenshots/${r.id}`, { data: { type: 'subscriptionAppStoreReviewScreenshots', id: r.id, attributes: { uploaded: true, sourceFileChecksum: md5 } } });
  console.log(s.attributes.productId, 'foto enviada');
}
