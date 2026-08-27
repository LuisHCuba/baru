import 'package:baru_app/data/supabase_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// O repositório anda antes da migração. O app não pode quebrar por isso.
///
/// Foi o que o usuário viu: "Não foi possível sincronizar (pet, loja)" a cada
/// gravação, porque `baru_inventory_items.equipped` — coluna que o app
/// inventou no mesmo turno — ainda não existia no banco.

void main() {
  group('reconhecer o erro de coluna', () {
    test('PGRST204 é coluna que falta, e diz qual', () {
      final e = PostgrestException(
        message: "Could not find the 'equipped' column of "
            "'baru_inventory_items' in the schema cache",
        code: 'PGRST204',
      );
      final r = ColunaAusenteNoRemoto.de(e);
      expect(r, isNotNull);
      expect(r!.coluna, 'equipped');
    });

    test('42703 do Postgres também conta', () {
      final e = PostgrestException(
        message: "column baru_inventory_items.'equipped' does not exist",
        code: '42703',
      );
      expect(ColunaAusenteNoRemoto.de(e)?.coluna, 'equipped');
    });

    test('erro de rede não vira erro de coluna', () {
      expect(
        ColunaAusenteNoRemoto.de(
          PostgrestException(message: 'timeout', code: '57014'),
        ),
        isNull,
      );
      expect(ColunaAusenteNoRemoto.de(Exception('offline')), isNull);
    });

    test('tabela ausente continua sendo outra coisa', () {
      final e = PostgrestException(
        message: "Could not find the table 'public.baru_progression' in the "
            'schema cache',
        code: 'PGRST205',
      );
      expect(
        ColunaAusenteNoRemoto.de(e),
        isNull,
        reason: 'tabela que falta é acionável de outro jeito',
      );
      expect(TabelaAusenteNoRemoto.de(e)?.tabela, 'baru_progression');
    });
  });
}
