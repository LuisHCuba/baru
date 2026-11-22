import 'dart:io';

import 'package:baru_app/data/familia.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_familia.dart';
import 'package:baru_app/screens/mapa_familia_screen.dart';
import 'package:baru_app/services/localizacao.dart';
import 'package:flutter_test/flutter_test.dart';

/// O responsável precisa saber POR QUE não há posição (bug de 21/11: o
/// painel só dizia "Ainda sem posição" e o celular nunca tinha se conectado).
void main() {
  final agora = DateTime(2026, 11, 22, 12);
  late T t;

  setUp(() {
    garanteTextosDaFamilia();
    t = T('pt');
  });

  CriancaNoMapa crianca({
    bool ligada = true,
    AparelhoDaCrianca? aparelho,
    DateTime? posicaoEm,
    DateTime? pedidoEm,
  }) =>
      CriancaNoMapa(
        id: 'c1',
        apelido: 'Bia',
        localizacao: ligada,
        pedidoEm: pedidoEm,
        aparelho: aparelho,
        atual: posicaoEm == null ? null : PosicaoDaCrianca(lat: 0, lng: 0, em: posicaoEm),
      );

  test('localização desligada: nada a explicar', () {
    expect(diagnosticoDoLocal(t, crianca(ligada: false), agora: agora), isNull);
  });

  test('celular nunca conectado', () {
    expect(diagnosticoDoLocal(t, crianca(), agora: agora), contains('ainda não se conectou'));
  });

  test('permissão negada, desligada e só durante o uso', () {
    expect(diagnosticoDoLocal(t, crianca(aparelho: const AparelhoDaCrianca(localEstado: 'negada')), agora: agora),
        contains('não deu permissão'));
    expect(diagnosticoDoLocal(t, crianca(aparelho: const AparelhoDaCrianca(localEstado: 'desligada')), agora: agora),
        contains('desligada nos ajustes'));
    expect(diagnosticoDoLocal(t, crianca(aparelho: const AparelhoDaCrianca(localEstado: 'quando_usa')), agora: agora),
        contains('durante o uso'));
  });

  test('versão antiga do app (não conta a permissão)', () {
    final ap = AparelhoDaCrianca(vistoEm: agora.subtract(const Duration(minutes: 5)));
    expect(diagnosticoDoLocal(t, crianca(aparelho: ap, posicaoEm: agora), agora: agora), contains('versão antiga'));
  });

  test('sem sinal há horas', () {
    final ap = AparelhoDaCrianca(localEstado: 'sempre', vistoEm: agora.subtract(const Duration(hours: 5)));
    final d = diagnosticoDoLocal(t, crianca(aparelho: ap, posicaoEm: agora.subtract(const Duration(hours: 6))), agora: agora);
    expect(d, contains('não dá sinal há 5 h'));
  });

  test('pedido a caminho', () {
    final ap = AparelhoDaCrianca(localEstado: 'sempre', vistoEm: agora);
    final d = diagnosticoDoLocal(t,
        crianca(aparelho: ap, posicaoEm: agora.subtract(const Duration(hours: 1)), pedidoEm: agora.subtract(const Duration(minutes: 2))),
        agora: agora);
    expect(d, contains('Pedido enviado há 2 min'));
  });

  test('tudo certo: posição recente com "sempre"', () {
    final ap = AparelhoDaCrianca(localEstado: 'sempre', vistoEm: agora);
    expect(diagnosticoDoLocal(t, crianca(aparelho: ap, posicaoEm: agora.subtract(const Duration(minutes: 20))), agora: agora),
        isNull);
  });

  test('o mapa lê o aparelho vindo do servidor', () {
    final c = CriancaNoMapa.doMapa({
      'id': 'c1',
      'apelido': 'Bia',
      'localizacao': true,
      'aparelho': {'plataforma': 'ios', 'visto_em': '2026-11-22T12:00:00Z', 'local_estado': 'quando_usa', 'versao': '1.0.7+17'},
    });
    expect(c.aparelho?.localEstado, 'quando_usa');
    expect(c.aparelho?.versao, '1.0.7+17');
  });

  test('a versão mandada ao servidor é a do pubspec', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(pubspec.split(':').last.trim(), versaoDoApp);
  });

  test('o nome da permissão no servidor', () {
    expect(PermissaoDeLocal.values.map((p) => p.noServidor).toSet(),
        {'desligada', 'nao_pedida', 'negada', 'quando_usa', 'sempre'});
  });
}
