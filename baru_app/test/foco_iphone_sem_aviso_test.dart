import 'package:baru_app/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// No iPhone não existe "aparecer sobre outros apps": começar o foco não pode
/// mostrar o aviso de sobreposição (parecia erro do app). O vigia do iPhone é
/// o escudo do Tempo de Uso + notificação (canal baru/tempo_de_tela).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('começar o foco no iPhone não avisa de sobreposição', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final chamadas = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('baru/tempo_de_tela'), (c) async {
      chamadas.add(c.method);
      return {'suportado': true, 'autorizacao': 'nao', 'apps': 0, 'categorias': 0, 'sites': 0};
    });
    final mensagens = <String>[];
    final app = AppState(onUserMessage: mensagens.add);
    app.startSession();
    await tester.pump(const Duration(milliseconds: 50));
    expect(mensagens.where((m) => m == app.t.vigiaSemPermissao), isEmpty);
    app.abandon();
    await tester.pump(const Duration(milliseconds: 50));
    app.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
