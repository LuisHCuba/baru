import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/row_codec.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('codec perfil ida e volta', () {
    const codec = BaruRowCodec();
    final s = AppState();
    s.lang = 'es';
    s.leaves = 40;
    s.owned = ['lily'];
    s.species = Species.otter;
    final snap = s.toSnapshot();
    final uid = '11111111-1111-1111-1111-111111111111';
    final row = codec.profileRow(userId: uid, deviceId: 'dev', s: snap);
    final back = codec.fromRows(
      profile: row,
      pet: codec.petRow(userId: uid, s: snap),
      wallet: codec.walletRow(userId: uid, s: snap),
      onboarding: codec.onboardingRow(userId: uid, s: snap),
      inventory: codec.inventoryRows(userId: uid, s: snap),
    );
    expect(back.lang, 'es');
    expect(back.leaves, 40);
    expect(back.owned, ['lily']);
    expect(back.species, Species.otter);
  });

  test('sessão abortada gera id estável no json', () {
    final rec = SessionRecord.fromJson({
      'at': '2026-08-26T12:00:00.000',
      'dur': 25,
      'completed': false,
      'aborted': true,
      'reward': 0,
    });
    expect(rec.id, isNotEmpty);
    expect(rec.aborted, isTrue);
    expect(SessionRecord.fromJson(rec.toJson()).id, rec.id);
  });
}
