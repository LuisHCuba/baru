// Compra dentro do app no iPhone (StoreKit 2), diretriz 3.1.1 da Apple.
//
// A Apple assina cada transação e cada notificação (JWS com a cadeia de
// certificados). A conferência usa a biblioteca oficial da Apple
// (@apple/app-store-server-library) com o certificado raiz Apple Root CA - G3
// fixado abaixo (o mesmo do Ecoin; válido até 2039).
//
// Os produtos da Apple são gravados com o nome dos produtos da Google
// (baru_assinatura, baru_familia, baru_familia_mais) e o plano base no mesmo
// formato: assim baru_acesso_de, o plano família e o ranking valem para as
// duas lojas sem mudar o banco.
//
// Compra de teste local (StoreKit no Xcode, ambiente "Xcode") não tem
// assinatura da Apple: só vale para as contas do segredo
// APPLE_TESTE_LOCAL_USUARIOS (ids separados por vírgula). Sem o segredo,
// nenhuma compra local libera acesso.

import { Buffer } from 'node:buffer'
import { Environment, SignedDataVerifier } from 'npm:@apple/app-store-server-library@3.1.0'

export const BUNDLE_ID = 'tech.lhcx.baru'
/** Apple ID do app na App Store Connect. */
export const APP_APPLE_ID = 6836622357

/** Produto da Apple → produto e plano base no formato da Google. */
export const PRODUTOS_APPLE: Record<string, { produto: string; planoBase: string }> = {
  'tech.lhcx.baru.mensal': { produto: 'baru_assinatura', planoBase: 'mensal' },
  'tech.lhcx.baru.anual': { produto: 'baru_assinatura', planoBase: 'anual' },
  'tech.lhcx.baru.familia.mensal': { produto: 'baru_familia', planoBase: 'familia-mensal' },
  'tech.lhcx.baru.familia.anual': { produto: 'baru_familia', planoBase: 'familia-anual' },
  'tech.lhcx.baru.familiamais.mensal': { produto: 'baru_familia_mais', planoBase: 'familia-mais-mensal' },
}

const APPLE_ROOT_CA_G3 = 'MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA=='

export type AmbienteApple = 'Production' | 'Sandbox' | 'Xcode'

/** Lê o "environment" do JWS sem conferir (só para escolher o verificador). */
export function ambienteDoJws(jws: string): AmbienteApple | null {
  try {
    const parte = jws.split('.')[1]
    const texto = new TextDecoder().decode(Uint8Array.from(atob(parte.replace(/-/g, '+').replace(/_/g, '/')), (c) => c.charCodeAt(0)))
    const corpo = JSON.parse(texto)
    const amb = corpo.environment ?? corpo.data?.environment
    return amb === 'Production' || amb === 'Sandbox' || amb === 'Xcode' ? amb : null
  } catch {
    return null
  }
}

export function verificador(ambiente: AmbienteApple): SignedDataVerifier {
  const raiz = [Buffer.from(APPLE_ROOT_CA_G3, 'base64')]
  const env = ambiente === 'Production' ? Environment.PRODUCTION : ambiente === 'Sandbox' ? Environment.SANDBOX : Environment.XCODE
  return new SignedDataVerifier(raiz, ambiente !== 'Xcode', env, BUNDLE_ID, ambiente === 'Production' ? APP_APPLE_ID : undefined)
}

export function testeLocalLiberado(usuarioId: string): boolean {
  const lista = (Deno.env.get('APPLE_TESTE_LOCAL_USUARIOS') ?? '').split(',').map((s) => s.trim()).filter(Boolean)
  return lista.includes(usuarioId)
}

export interface TransacaoApple {
  produtoApple: string
  produto: string
  planoBase: string
  transacaoOriginalId: string
  expiraEm: string
  revogadaEm: string | null
  conta: string | null
  ambiente: AmbienteApple
}

/** Confere e lê uma transação assinada. Lança erro se a assinatura não bater. */
export async function lerTransacao(jws: string, ambiente: AmbienteApple): Promise<TransacaoApple> {
  const t = await verificador(ambiente).verifyAndDecodeTransaction(jws)
  const mapa = t.productId ? PRODUTOS_APPLE[t.productId] : undefined
  if (!mapa) throw new Error('produto_desconhecido')
  if (!t.originalTransactionId || !t.expiresDate) throw new Error('transacao_incompleta')
  return {
    produtoApple: t.productId!,
    produto: mapa.produto,
    planoBase: mapa.planoBase,
    transacaoOriginalId: t.originalTransactionId,
    expiraEm: new Date(t.expiresDate).toISOString(),
    revogadaEm: t.revocationDate ? new Date(t.revocationDate).toISOString() : null,
    conta: t.appAccountToken ? t.appAccountToken.toLowerCase() : null,
    ambiente,
  }
}
