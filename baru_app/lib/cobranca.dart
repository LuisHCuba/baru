/// Compra dentro do app (BL-07).
///
/// Enquanto a cobrança pela Google Play não existir, o app não mostra o
/// paywall, o plano nem "Restaurar compras": anunciar preço e teste grátis
/// sem cobrar pela loja fere a política de pagamentos da Play e promete algo
/// que o app não faz. Quando o Play Billing entrar, basta virar para `true`.
const cobrancaNaLoja = false;
