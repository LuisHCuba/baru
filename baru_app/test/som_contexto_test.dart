// O som do Baru não pausa a música de ninguém.
//
// Auditoria da Onda 1 (docs/auditoria/onda-1.md, 2a): a correção inteira do
// item era o contexto de áudio, e nada a conferia. Trocar `audioFocus` para
// `gain` (o padrão do plugin) voltaria a pausar o Spotify a cada toque, sem
// quebrar teste nenhum.
import 'package:audioplayers/audioplayers.dart';
import 'package:baru_app/services/som_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final c = SomService.contexto;

  test('Android: efeito de interface, sem pedir foco de áudio', () {
    expect(c.android.audioFocus, AndroidAudioFocus.none);
    expect(c.android.usageType, AndroidUsageType.assistanceSonification);
    expect(c.android.contentType, AndroidContentType.sonification);
    // Viva-voz ligado tiraria o som do fone de quem está ouvindo música.
    expect(c.android.isSpeakerphoneOn, isFalse);
    expect(c.android.stayAwake, isFalse);
  });

  test('iOS: ambiente, que obedece a chave lateral e mistura com a música',
      () {
    // Construir o contexto já é parte do teste: o plugin recusa por
    // asserção combinações inválidas (ambient + mixWithOthers era uma).
    expect(c.iOS.category, AVAudioSessionCategory.ambient);
  });
}
