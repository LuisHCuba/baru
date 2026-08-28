import 'dart:convert';

import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_sobreposicao.dart';
import 'package:baru_app/services/vigia_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fala do companheiro varia com o app.
///
/// **O defeito.** O vigia sabia qual pacote estava na frente e mandava sempre
/// a mesma frase. "O YouTube de novo?" e "o TikTok de novo?" são falas
/// diferentes, e o vigia tinha a informação para escolher — só não tinha o
/// dicionário.
///
/// **A regra dura que estes testes protegem:** o lado nativo não escreve
/// texto de produto. Toda frase nasce no catálogo Dart, traduzida, e viaja
/// pronta. O Kotlin escolhe uma linha; escolher não é escrever.
///
/// O que **não** dá para provar aqui: que o `VigiaDaSessao` decodifica o
/// envelope no aparelho. Isso é Kotlin, não roda em `flutter test`, e está
/// registrado em BL-12.

/// Grava o que foi para a plataforma.
class _CanalEspiao {
  _CanalEspiao(this.nome);

  final String nome;
  final chamadas = <MethodCall>[];

  MethodChannel arma() {
    final canal = MethodChannel(nome);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (chamada) async {
      chamadas.add(chamada);
      return true;
    });
    return canal;
  }

  MethodCall? ultima(String metodo) {
    for (final c in chamadas.reversed) {
      if (c.method == metodo) return c;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tiktok = 'com.zhiliaoapp.musically';
  const youtube = 'com.google.android.youtube';
  const instagram = 'com.instagram.android';
  const netflix = 'com.netflix.mediaclient';

  group('o catálogo de apps', () {
    const padrao = ClassificacaoPadrao();

    test('cobre muito mais que o TikTok', () {
      // A lista que o dono do produto citou, nome por nome.
      for (final p in [
        youtube,
        instagram,
        'com.reddit.frontpage',
        'com.twitter.android',
        'com.kwai.video',
        'tv.twitch.android.app',
        netflix,
        'com.facebook.katana',
        'com.snapchat.android',
        tiktok,
      ]) {
        expect(
          padrao.de(p),
          CategoriaDeApp.dispersivo,
          reason: '$p tem de entrar como dispersivo',
        );
      }
    });

    test('conhece jogos populares, não só redes sociais', () {
      for (final p in [
        'com.dts.freefireth',
        'com.roblox.client',
        'com.supercell.clashroyale',
        'com.mojang.minecraftpe',
        'com.tencent.ig',
      ]) {
        expect(padrao.de(p), CategoriaDeApp.dispersivo, reason: p);
        expect(padrao.familia(p), FamiliaDeApp.jogo, reason: p);
      }
    });

    test('Telegram é conhecido, com fala, e segue neutro na meta', () {
      // O contrato de produto §8 põe mensagem em neutro. Mudar isso exige
      // ADR — o que dá para fazer sem ADR é o companheiro **saber falar**
      // sobre ele, que era o pedido.
      const telegram = 'org.telegram.messenger';
      expect(padrao.de(telegram), CategoriaDeApp.neutro);
      expect(padrao.familia(telegram), FamiliaDeApp.mensagem);
      expect(T('pt').falaDoApp(telegram), contains('Telegram'));
    });

    test('todo app conhecido tem nome legível, e não o pacote cru', () {
      for (final p in ClassificacaoPadrao.porNome) {
        final nome = padrao.nome(p);
        expect(nome.trim(), isNotEmpty, reason: p);
        expect(nome, isNot(p), reason: '$p ficou com o id no lugar do nome');
      }
      // `com.zhiliaoapp.musically` não diz nada a ninguém; "TikTok" diz.
      expect(padrao.nome(tiktok), 'TikTok');
      expect(padrao.nome('com.mercadolibre'), 'Mercado Livre');
      // Desconhecido cai na heurística, que é feia mas honesta.
      expect(padrao.nome('com.empresa.appinterno'), 'Appinterno');
    });

    test('nenhum app com fala é um pacote que a contagem exclui', () {
      // Um app excluído nunca aparece como "o da frente" para a contagem, e
      // ter fala para ele seria fala morta.
      const exclusoes = ExclusoesDeContagem();
      for (final p in ClassificacaoPadrao.comFala) {
        expect(exclusoes.excluido(p), isFalse, reason: p);
      }
    });

    test('a tabela cresceu de dezenas para uma centena de apps', () {
      expect(ClassificacaoPadrao.conhecidos, greaterThan(100));
    });
  });

  group('a fala escolhida pelo app', () {
    test('o YouTube não ouve a mesma frase que o TikTok', () {
      final t = T('pt');
      final noYoutube = t.falaDoApp(youtube)!;
      final noTiktok = t.falaDoApp(tiktok)!;

      expect(noYoutube, contains('YouTube'));
      expect(noTiktok, contains('TikTok'));

      // Não basta trocar o nome: a frase em volta também muda, porque vídeo
      // longo e vídeo curto prendem a pessoa de jeitos diferentes.
      expect(
        noYoutube.replaceAll('YouTube', 'X'),
        isNot(noTiktok.replaceAll('TikTok', 'X')),
        reason: 'mesma frase com o nome trocado não é "a fala varia"',
      );
    });

    test('cada família tem a sua frase', () {
      final t = T('pt');
      final moldes = <String>{
        for (final f in FamiliaDeApp.values) t.moldeDaFala(f),
      };
      expect(
        moldes,
        hasLength(FamiliaDeApp.values.length),
        reason: 'duas famílias com a mesma frase é uma família a menos',
      );
      for (final m in moldes) {
        expect(m, contains('{app}'), reason: 'a frase tem de nomear o app');
      }
    });

    test('app sem família não inventa fala', () {
      // Banco, câmera, relógio: o companheiro não tem nada de específico a
      // dizer, e a fala padrão da sessão é mais honesta que uma frase que
      // acusa dispersão onde não houve.
      expect(T('pt').falaDoApp('com.nu.production'), isNull);
      expect(T('pt').falaDoApp('com.empresa.appinterno'), isNull);
    });

    test('a fala sai traduzida nos quatro idiomas', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final fala = T(lang).falaDoApp(netflix);
        expect(fala, isNotNull, reason: lang);
        expect(fala, contains('Netflix'), reason: lang);
        expect(
          fala,
          isNot(contains('sobFala')),
          reason: 'chave crua na tela em $lang — o catálogo não registrou',
        );
      }
    });

    test('o dicionário cobre os apps com fala, e só eles', () {
      final mapa = falasPorPacote(T('pt'));
      expect(mapa.keys.toSet(), ClassificacaoPadrao.comFala.toSet());
      expect(mapa[instagram], contains('Instagram'));
    });
  });

  group('o envelope que chega ao vigia', () {
    test('sem falas por app, o formato não muda', () {
      // Compatibilidade com quem ainda não passa o mapa: vai a string crua,
      // e o lado nativo nem precisa saber que o recurso existe.
      expect(VigiaService.empacotaFalas('Ei', const {}), 'Ei');
    });

    test('com falas por app, vai um dicionário com a padrão junto', () {
      final bruto = VigiaService.empacotaFalas('Ei', {
        youtube: 'O YouTube de novo?',
      });
      final lido = jsonDecode(bruto) as Map<String, dynamic>;

      expect(lido[youtube], 'O YouTube de novo?');
      expect(
        lido[VigiaService.chaveDaFalaPadrao],
        'Ei',
        reason: 'app fora do dicionário tem de ouvir alguma coisa',
      );
    });

    test('o dicionário atravessa o canal até a plataforma', () async {
      final espiao = _CanalEspiao('baru/vigia-fala-teste');
      VigiaService.instance
        ..canal = espiao.arma()
        ..zeraParaTeste();
      addTearDown(() {
        VigiaService.instance
          ..canal = const MethodChannel('baru/overlay')
          ..zeraParaTeste();
      });

      await VigiaService.instance.comeca(
        fala: 'Ei',
        pelo: 1,
        especie: 'capybara',
        acaoFechar: 'x',
        acaoMais: 'y',
        notifTitulo: 't',
        notifCorpo: 'c',
        falasPorPacote: falasPorPacote(T('pt')),
      );

      final args = espiao.ultima('vigiaComeca')!.arguments as Map;
      final lido = jsonDecode(args['fala'] as String) as Map<String, dynamic>;
      expect(lido[tiktok], contains('TikTok'));
      expect(lido[youtube], contains('YouTube'));
      expect(lido[VigiaService.chaveDaFalaPadrao], 'Ei');
    });
  });

  group('os quatro idiomas do contrato', () {
    const base = 'pt';
    final pt = textosDaSobreposicao[base]!;

    test('o catálogo do módulo tem os quatro', () {
      expect(textosDaSobreposicao.keys.toSet(), {'pt', 'en', 'es', 'zh'});
    });

    for (final lang in ['en', 'es', 'zh']) {
      test('$lang tem as mesmas chaves de $base', () {
        final m = textosDaSobreposicao[lang]!;
        expect(m.keys.toSet(), pt.keys.toSet(), reason: lang);
      });

      test('$lang preserva os placeholders', () {
        final m = textosDaSobreposicao[lang]!;
        final re = RegExp(r'\{(\w+)\}');
        for (final chave in pt.keys) {
          Set<String> tokens(String? v) =>
              re.allMatches(v ?? '').map((x) => x.group(1)!).toSet();
          expect(
            tokens(m[chave]),
            tokens(pt[chave]),
            reason: 'placeholders divergem em $lang.$chave — a tela mostraria '
                'o token cru ou perderia o valor',
          );
        }
      });

      test('$lang não tem texto vazio', () {
        for (final e in textosDaSobreposicao[lang]!.entries) {
          expect(e.value.trim(), isNotEmpty, reason: '$lang.${e.key}');
        }
      });
    }

    test('nenhuma chave do módulo colide com o catálogo principal', () {
      // O principal ganha: uma chave repetida aqui seria texto que nunca
      // aparece, e ninguém descobriria até alguém trocar a frase e nada
      // mudar na tela.
      final principal = T.catalog[base]!.keys.toSet();
      expect(pt.keys.toSet().intersection(principal), isEmpty);
    });
  });
}
