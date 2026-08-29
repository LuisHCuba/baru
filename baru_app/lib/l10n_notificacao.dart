/// Os textos que só existem dentro de uma notificação.
///
/// Ficam num mapa próprio, registrado sob demanda, porque `lib/l10n.dart` é
/// o ponto de colisão de qualquer trabalho em paralelo — ver `T.registra`.
///
/// **Por que este arquivo existe.** A barra de notificações é o único lugar
/// do produto onde a fala precisa atravessar o `MethodChannel` e ser
/// desenhada por código Kotlin. A regra dura é que o lado nativo **não
/// escreve texto de produto**: ele recebe cada palavra pronta e traduzida
/// (ver `OverlayDoBaru` e `VigiaDaSessao`). Um rótulo de ação que nascesse
/// em Kotlin sairia em português para um usuário chinês e ninguém veria —
/// notificação é justamente o que se lê quando o app não está aberto.
library;

import 'l10n.dart';

const textosDaNotificacao = <String, Map<String, String>>{
  'pt': {
    'notifBarraVoltar': 'Voltar ao Baru',
    'notifDescansoDesistir': 'Encerrar',
  },
  'en': {
    'notifBarraVoltar': 'Back to Baru',
    'notifDescansoDesistir': 'End it',
  },
  'es': {
    'notifBarraVoltar': 'Volver a Baru',
    'notifDescansoDesistir': 'Terminar',
  },
  'zh': {
    'notifBarraVoltar': '回到 Baru',
    'notifDescansoDesistir': '结束',
  },
};

void garanteTextosDaNotificacao() => T.registra(textosDaNotificacao);

/// Os acessos, como getters.
///
/// `t.s('chave')` funcionaria, mas erro de digitação só apareceria na barra
/// de notificações da pessoa. Extensão dá o erro no compilador, que é onde
/// ele custa barato.
extension TextosDaNotificacao on T {
  /// O botão que traz a pessoa de volta ao app.
  ///
  /// Existe como **ação** e não só como toque no corpo da notificação
  /// porque a notificação da sessão passou a ser fixa e silenciosa: ela vive
  /// na parte de baixo da gaveta, encolhida, e nesse estado o corpo é uma
  /// linha de texto que ninguém percebe ser clicável.
  String get notifBarraVoltar => s('notifBarraVoltar');

  /// Encerrar a missão do descanso pela barra.
  ///
  /// Não reusa `notifSessaoDesistir` ("Desistir"): desistir do foco custa a
  /// recompensa da sessão, e encerrar o descanso não custa nada — o melhor
  /// do dia fica guardado (§1, sem punição). Palavras diferentes para
  /// consequências diferentes.
  String get notifDescansoDesistir => s('notifDescansoDesistir');
}
