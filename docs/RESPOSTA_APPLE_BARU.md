# Baru 1.0 — resposta à revisão de 23/11/2026 (rascunho, NÃO ENVIADO)

Envio só com o ok do Luis (regra da conta: recusas repetidas ameaçam a conta inteira).
Antes de responder e reenviar:

1. Apple confirmar a conta bancária (contrato de apps pagos ativo).
2. Criar o grupo "Planos do Baru" com os 5 produtos (ids em PLANO_APPLE_BARU.md),
   preços decididos pelo Luis, e cadastrar a URL de avisos da App Store.
3. Build novo no TestFlight com a compra pela Apple e sem o modo "location"
   em segundo plano; compra de teste (sandbox) num iPhone com iOS 17 ou mais.
4. Trocar as notas ao revisor pelo texto abaixo e anexar os produtos à versão.

## O que a Apple apontou (submission 119c32b5, 23/11)

1. 2.5.4: UIBackgroundModes declarava "location" sem recurso de localização contínua.
2. 3.1.1: o app acessa conteúdo pago comprado fora dele ("Digital Plans") que não
   está à venda pela compra dentro do app.

(A 4.3 de 21/11 não voltou: a explicação foi aceita.)

## O que foi feito (25/11)

- 2.5.4: o modo "location" saiu do Info.plist e o app não liga mais o rastreio
  contínuo. A localização da família usa só mudança significativa, visitas e
  cerca, que não precisam do modo.
- 3.1.1: os 5 planos (Individual mensal e anual, Família mensal e anual,
  Família+) estão à venda no iPhone pela compra dentro do app (StoreKit 2),
  com restaurar, gerenciar, renovação explicada, termos e privacidade. O
  servidor confere a transação assinada pela Apple e recebe os avisos da App
  Store.
- Nenhum caminho do app ou da ficha leva aos planos do site: suporte e
  marketing em meubaru.com/ajuda, privacidade em meubaru.com/privacidade/ios,
  termos do app em meubaru.com/termos/ios (páginas sem preço e sem pagamento
  pelo site), e a linha do painel saiu da descrição.

## Resposta (inglês, para colar na Central de Resoluções)

Hello,

Thank you for the review. Both points are addressed in the new build.

Guideline 2.5.4 - Software Requirements
The app no longer declares "location" in UIBackgroundModes. Family location
sharing only uses the significant-change location service, visits and region
monitoring, which do not require the background mode, as you suggested.

Guideline 3.1.1 - In-App Purchase
Every plan is now available for purchase in the app with In-App Purchase:
Individual (monthly and yearly), Family (monthly and yearly) and Family+
(monthly), in the "Planos do Baru" subscription group. The subscription
screen (Settings > Your account > Subscribe to Baru, and at the end of the
free trial) shows each plan with the App Store price, the auto-renewal terms,
Restore Purchases, Manage Subscription, Terms of Use and Privacy Policy. The
app does not link to or mention any other way to buy, and the support,
marketing and privacy URLs now point to pages without plans or prices.

Best regards,
Luis Cuba

## Notas ao revisor (inglês, trocar na ficha no reenvio)

Baru is a focus and digital wellbeing app with an optional family mode
(parental controls). Sign in with the demo account below (or Sign in with
Apple / Google).

Subscriptions: every plan is sold in the app with In-App Purchase (group
"Planos do Baru"). Open Settings > Your account > Subscribe to Baru. The same
screen opens when the 7-day free trial ends. Restore Purchases and Manage
Subscription are on that screen.

Family mode: the Bonds tab. A parent creates a bond and adds a child's phone
with a one-time code; on the child's iPhone (choose "For my child" on the
first screen) the app uses Screen Time (FamilyControls, approved: Family
Controls Distribution) to apply the parent's daily goal, screen-free hours
and pause. Location sharing is optional: the Always permission is only
requested on the child's device after the parent turns location on and
confirms consent, the child always sees that location is on, and the app
uses significant-change, visits and region monitoring only (no continuous
background location).
