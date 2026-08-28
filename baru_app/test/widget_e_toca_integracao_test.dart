import 'package:baru_app/models.dart';
import 'package:baru_app/navegacao.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// O caminho que o widget da tela inicial usa para abrir a tela certa.
///
/// `RemoteViews` roda no processo do launcher e não consegue empurrar estado
/// para o app: o destino viaja como endereço, num `Intent` com
/// `baru://<tela>`. Um esquema próprio não põe barra depois dos
/// dois-pontos, então a tela chega no **host** e não no caminho — sem ler o
/// host, todo toque no widget abriria a home.

void main() {
  const parser = BaruRouteParser();

  Future<AppScreen> le(String url) =>
      parser.parseRouteInformation(RouteInformation(uri: Uri.parse(url)));

  group('o endereço do widget', () {
    test('a tela vem do host quando o esquema é nosso', () async {
      expect(await le('baru://sequencia'), AppScreen.sequencia);
      expect(await le('baru://tempo'), AppScreen.tempo);
      expect(await le('baru://trilha'), AppScreen.trilha);
    });

    test('baru://home é a home', () async {
      expect(await le('baru://home'), AppScreen.home);
    });

    test('host desconhecido cai na home em vez de quebrar', () async {
      expect(await le('baru://inexistente'), AppScreen.home);
    });
  });

  group('o endereço de sempre continua valendo', () {
    test('caminho comum ainda resolve', () async {
      expect(await le('/sequencia'), AppScreen.sequencia);
      expect(await le('/loja'), AppScreen.shop);
      expect(await le('/'), AppScreen.home);
    });

    test('toda tela tem um caminho que volta para ela', () async {
      for (final tela in AppScreen.values) {
        expect(await le(tela.caminho), tela, reason: tela.name);
      }
    });
  });
}
