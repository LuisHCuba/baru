# Estado — 2026-08-26, ciclo 1 (documentação)

Branch: `night/2026-08-26` | Último commit: docs base | Build: **verde**

## Pronto e funcionando

- MVP das 8 telas em pt/en/es/zh, rodando com Supabase real.
- Backend verificado no projeto `Baru` (`slqpuppkapiewjqvedtj`, sa-east-1):
  13 tabelas, 50 políticas RLS, isolamento entre usuários testado por query.
- `flutter analyze` limpo; `flutter test` 27/27 verdes.
- Projeto sob git com histórico e remote (antes não havia nenhum).
- Documentação base criada (este arquivo + README + 7 docs).

## Em andamento

Ciclo 1 concluído. **Próximo passo exato:** B-02 — reconciliar migrations com o
banco real: criar migration de adoção do `public.rls_auto_enable()` (ADR-002) e
reescrever os blocos legados da migration 5 com `execute format` (ADR-003).

## Próximos 5 itens da fila

1. B-02 — reconciliar migrations × banco real.
2. B-03 — crash de i18n em en/es/zh (5 chaves só existem em pt).
3. B-04 — bônus de +15 folhas por fechar abaixo da meta (regra de produto).
4. B-05 — virada de semana e `todayIndex`.
5. B-06 — máscara de sync perdida em falha remota.

## Riscos e dívidas conhecidas

- **Sessão de foco não sobrevive a background/kill** (B-07): timer sem relógio
  de parede, sessão em curso não persistida. É o caminho core do produto.
- Schema do banco ainda sem ledger de migrations (BL-01).
- Migrations nunca validadas contra banco limpo (BL-02).
- Economia de folhas é autoritativa no cliente.
- `AppState` com mais de 800 linhas concentra domínio, plataforma e
  persistência.
- Camada de repositório com metade dos métodos nunca chamados.

## Bloqueios para o humano

BL-01 ledger de migrations · BL-02 validar migrations em banco limpo ·
BL-03 proteção de senha vazada · BL-04 usuário de teste não confirmado ·
BL-05 assinatura de release Android · BL-06 entitlement de Screen Time no iOS ·
BL-07 IAP · BL-08 conta do `gh` para push.
Detalhes em [BLOCKERS.md](BLOCKERS.md).

## Comandos para rodar e validar agora

```
cd baru_app
flutter pub get
flutter analyze
flutter test
flutter run
```
