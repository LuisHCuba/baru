# Estado — 2026-08-27, fim do turno

Branch: `night/2026-08-27`, integrada em `main` | Build: **verde**

| Portão | Resultado (execução real) |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **324 passando, 1 pulado** (era 151 no início do dia) |
| `flutter test test/integration` | 7/7 contra Supabase local |
| `supabase db reset` em banco limpo | **8 migrations · 15 tabelas · 58 políticas · nenhuma sem RLS** |
| Evidência visual | 40 PNGs em `docs/evidence/2026-08-27/` |

## Abra o app e você vê

Frases que são verdade hoje e não eram ontem:

- **O botão voltar do aparelho funciona**: num detalhe volta um passo, numa
  aba volta para a home, e só na home sai do app. Durante a sessão, pergunta.
- **As telas entram com transição** e a barra de destinos é fixa.
- **Dá para acariciar o Baru**: ele acompanha a mão, aperta os olhos, o pelo
  se levanta sob o dedo, sobem corações, e a mão ronrona.
- **As quatro espécies são um elenco coerente**, todas de frente, com cabeça
  grande e cara legível.
- **O Baru respira, pisca e reage ao toque**, e **faz coisas sozinho**: a
  cada 7–15 s parado ele se espreguiça com bocejo, sacode a cabeça ou olha em
  volta.
- **Insistir no carinho faz subir coraçõezinhos** — do terceiro toque em 3 s.
- O habitat tem céu em gradiente, colinas que derivam e reflexos andando na
  água.
- **O habitat às 22h é diferente do das 9h** — céu índigo, lua com halo, água
  escura.
- **Comprar um item o faz cair na cena com mola**, e ele projeta sombra.
- **"Seu tempo de tela"** mostra quanto conta para a meta, quanto foi no total,
  a quebra por categoria e a lista por app. O Spotify aparece como Áudio, fora
  da meta.
- **Uma aba "Trilha"** com nível, XP, o próximo passo em destaque e doze marcos
  ligados por uma linha.
- **Subir de nível toma a tela** com partículas e háptico.
- **Uma aba "Missões"** com progresso x/y, recompensa exata, prazo e um botão
  "Resgatar" que faz o saldo de folhas subir animado.
- **A sessão de foco aparece na barra de notificações** com contagem regressiva
  e botão "Desistir".

## Pronto e funcionando

- Cinco fatias verticais completas neste turno (dado → regra → persistência →
  tela → animação → háptico → 4 idiomas → teste → evidência).
- Design system em código: tokens de cor, espaço, raio, elevação e tipografia;
  sistema de movimento com durações nomeadas e curvas com física.
- Nunito empacotada: o app não baixa mais a própria fonte.
- Tempo de tela por contabilidade de intervalos, não por soma bruta.
- Progressão real: XP, níveis, doze marcos, espécies desbloqueáveis.
- Missões com sorteio determinístico e resgate idempotente.
- Backend: 14 tabelas com RLS, schema reproduzível do zero.

## Em andamento

Nada pela metade. Todos os ciclos fecharam com portões verdes.

**Próximo passo exato:** aplicar as migrations 7 e 8 no Supabase remoto
(**BL-10**) — é o que faz o "erro ao sincronizar" sumir. Precisa de um humano
com acesso ao projeto; o comando está no arquivo de bloqueios.

## Próximos itens da fila

1. **Aplicar as migrations no remoto** (BL-10).
2. **B-15 assinatura de release do Android** — único bloqueio de publicação.
3. **Estágios de habitat visíveis** — o dado existe (`estagioDoHabitat` sobe
   com os marcos) mas a cena ainda não muda com ele.
4. **Lembretes com propósito** (§6) — sequência em risco, missão quase
   concluída, marco ao alcance.
5. **Onboarding e paywall no novo design system** — as duas telas que ainda
   usam os valores antigos.

## Riscos e dívidas conhecidas

- **O banco remoto está atrás do repositório** (BL-10): faltam
  `baru_app_categories` e `baru_progression`. O app avisa qual tabela falta e
  segue gravando local; nada se perde, mas nada de ajustes, tempo de tela e
  progressão sobe.
- **Nada foi verificado em aparelho.** Animações, notificação e permissão de
  uso têm teste, mas ninguém rodou o app num telefone depois deste turno.
- **A permissão de tempo de tela nunca rodou contra o Android real.** A
  reconstrução de intervalos tem 25 casos sintéticos; a leitura dos eventos
  crus depende de aparelho.
- **Economia autoritativa no cliente** — vira problema no dia do IAP.
- **`AppState` passou de 1200 linhas.** Concentra domínio, plataforma e
  persistência.
- **Nada foi aplicado no Supabase remoto.** A migration 7 existe no
  repositório e foi validada localmente; aplicar é do humano.

## Bloqueios para o humano

| # | O quê |
|---|---|
| BL-01 | Ledger de migrations ausente no projeto remoto |
| BL-03 | Proteção contra senha vazada desligada |
| BL-04 | Um usuário de teste sem e-mail confirmado |
| BL-05 | Keystore de release do Android |
| BL-06 | Entitlement de Screen Time no iOS |
| BL-07 | Produtos de IAP nas lojas |
| BL-09 | **Verificar a notificação da sessão num aparelho** (roteiro no arquivo) |
| BL-10 | **Aplicar as migrations 7 e 8 no Supabase remoto** — é a causa do "erro ao sincronizar" |

## Comandos para rodar e validar agora

```
cd baru_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Evidência visual e banco local:

```
flutter test test/evidencia_test.dart      # regenera os PNGs
supabase start && supabase db reset        # migrations do zero
flutter test test/integration --dart-define=BARU_TEST_URL=http://127.0.0.1:54321 --dart-define=BARU_TEST_KEY=<chave>
```
