import 'package:baru_app/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trava a regra §2 do contrato de produto: quatro idiomas de primeira classe.
///
/// `T.s()` faz `_m[key] as String`. Uma chave que exista só em `pt` não é um
/// texto faltando: é um `_TypeError` em runtime. Já aconteceu — `syncFail`,
/// usada no handler de erro de sync, derrubava o app em en/es/zh.
void main() {
  const base = 'pt';
  final outros = T.catalog.keys.where((l) => l != base).toList();
  final pt = T.catalog[base]!;

  test('os 4 idiomas do contrato existem no catálogo', () {
    expect(T.catalog.keys.toSet(), {'pt', 'en', 'es', 'zh'});
  });

  for (final lang in outros) {
    final m = T.catalog[lang]!;

    test('$lang tem exatamente as mesmas chaves de $base', () {
      expect(
        m.keys.toSet().difference(pt.keys.toSet()),
        isEmpty,
        reason: '$lang tem chave que não existe em $base',
      );
      expect(
        pt.keys.toSet().difference(m.keys.toSet()),
        isEmpty,
        reason: 'chave de $base faltando em $lang — vira crash, não texto vazio',
      );
    });

    test('$lang tem a mesma forma de $base em cada chave', () {
      for (final key in pt.keys) {
        if (!m.containsKey(key)) continue; // já reportado no teste acima
        _mesmaForma(pt[key], m[key], '$lang.$key');
      }
    });

    test('$lang preserva os placeholders de $base', () {
      for (final key in pt.keys) {
        if (!m.containsKey(key)) continue;
        final esperado = _placeholders(pt[key]);
        final achado = _placeholders(m[key]);
        expect(
          achado,
          esperado,
          reason: 'placeholders divergem em $lang.$key — a UI mostraria '
              'o token cru ou perderia o valor',
        );
      }
    });

    test('$lang não tem texto vazio', () {
      for (final key in m.keys) {
        _naoVazio(m[key], '$lang.$key');
      }
    });
  }

  test('regressão: as chaves de auth e sync resolvem nos 4 idiomas', () {
    for (final lang in T.catalog.keys) {
      final t = T(lang);
      for (final valor in [
        t.syncFail,
        t.bootstrapOffline,
        t.authAttachFail,
        t.authConfirmEmail,
        t.authBootstrapLoading,
      ]) {
        expect(valor, isNotEmpty, reason: 'vazio em $lang');
      }
    }
  });

  test('os acessores estruturados resolvem nos 4 idiomas', () {
    const moods = ['radiant', 'content', 'neutral', 'sleepy', 'missing_you'];
    const especies = ['capybara', 'otter', 'tortoise', 'owl'];

    for (final lang in T.catalog.keys) {
      final t = T(lang);
      expect(t.quizQ.length, 3, reason: 'quizQ em $lang');
      expect(t.quizO.length, 3, reason: 'quizO em $lang');
      for (final opcoes in t.quizO) {
        expect(opcoes.length, 4, reason: 'opções do quiz em $lang');
      }
      expect(t.items.length, 8, reason: 'itens da loja em $lang');
      expect(t.days.length, 7, reason: 'dias da semana em $lang');
      expect(t.tabs.length, 4, reason: 'tabs em $lang');

      for (final mood in moods) {
        expect(t.moodCap(mood), isNotEmpty, reason: 'moodCap $mood/$lang');
        expect(t.moodSub(mood), isNotEmpty, reason: 'moodSub $mood/$lang');
        expect(t.moodLbl(mood), isNotEmpty, reason: 'moodLbl $mood/$lang');
      }
      for (final sp in especies) {
        expect(t.species(sp).length, 2, reason: 'species $sp/$lang');
        expect(t.animalName(sp), isNotEmpty, reason: 'animalName $sp/$lang');
      }

      expect(t.freezeNote(0), isNotEmpty);
      expect(t.freezeNote(1), isNotEmpty);
      expect(t.freezeNote(2), isNotEmpty);
      expect(t.streakLabel(1), isNotEmpty);
      expect(t.streakLabel(4), isNotEmpty);
      expect(t.formatLongDate(DateTime(2026, 8, 26)), isNotEmpty);
      expect(t.formatReportDate(DateTime(2026, 8, 26)), isNotEmpty);
    }
  });

  test('idioma desconhecido cai em pt em vez de estourar', () {
    expect(T('kl').start, T('pt').start);
  });
}

void _mesmaForma(Object? a, Object? b, String caminho) {
  if (a is String) {
    expect(b, isA<String>(), reason: '$caminho deveria ser String');
    return;
  }
  if (a is List) {
    expect(b, isA<List>(), reason: '$caminho deveria ser List');
    final lb = b as List;
    expect(lb.length, a.length, reason: '$caminho: tamanho diferente');
    for (var i = 0; i < a.length; i++) {
      _mesmaForma(a[i], lb[i], '$caminho[$i]');
    }
    return;
  }
  if (a is Map) {
    expect(b, isA<Map>(), reason: '$caminho deveria ser Map');
    final mb = b as Map;
    expect(
      mb.keys.toSet(),
      a.keys.toSet(),
      reason: '$caminho: chaves internas divergem',
    );
    for (final k in a.keys) {
      _mesmaForma(a[k], mb[k], '$caminho.$k');
    }
  }
}

final _rePlaceholder = RegExp(r'\{(\w+)\}');

Set<String> _placeholders(Object? valor) {
  final out = <String>{};
  void anda(Object? v) {
    if (v is String) {
      for (final m in _rePlaceholder.allMatches(v)) {
        out.add(m.group(1)!);
      }
    } else if (v is List) {
      v.forEach(anda);
    } else if (v is Map) {
      v.values.forEach(anda);
    }
  }

  anda(valor);
  return out;
}

void _naoVazio(Object? valor, String caminho) {
  if (valor is String) {
    expect(valor.trim(), isNotEmpty, reason: '$caminho está vazio');
  } else if (valor is List) {
    for (var i = 0; i < valor.length; i++) {
      _naoVazio(valor[i], '$caminho[$i]');
    }
  } else if (valor is Map) {
    valor.forEach((k, v) => _naoVazio(v, '$caminho.$k'));
  }
}
