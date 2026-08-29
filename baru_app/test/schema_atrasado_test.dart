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

    test('o nome sai das quatro gramáticas em que o erro chega', () {
      // Só a primeira estava reconhecida. As outras três acontecem de
      // verdade — o Postgres não usa aspas simples — e sem o nome quem
      // degrada não sabe se a coluna recusada era mesmo opcional: ou degrada
      // por qualquer erro, ou não degrada nunca.
      String? nome(String mensagem, String codigo) =>
          ColunaAusenteNoRemoto.de(
            PostgrestException(message: mensagem, code: codigo),
          )?.coluna;

      expect(
        nome(
          "Could not find the 'som' column of 'baru_settings' in the schema "
          'cache',
          'PGRST204',
        ),
        'som',
        reason: 'PostgREST, aspas simples',
      );
      expect(
        nome(
          'column "som" of relation "baru_settings" does not exist',
          '42703',
        ),
        'som',
        reason: 'Postgres num insert, aspas duplas',
      );
      expect(
        nome('column baru_settings.som does not exist', '42703'),
        'som',
        reason: 'Postgres num select, sem aspa nenhuma — era o que faltava',
      );
      expect(
        nome('column som does not exist', '42703'),
        'som',
        reason: 'sem a tabela na frente',
      );
    });

    test('sem nome reconhecível o erro continua sendo de coluna', () {
      // "desconhecida" nunca casa com uma coluna declarada opcional, então a
      // degradação não acontece por engano — mas o tipo continua certo.
      expect(
        ColunaAusenteNoRemoto.de(
          PostgrestException(message: 'algo bem diferente', code: 'PGRST204'),
        )?.coluna,
        'desconhecida',
      );
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
