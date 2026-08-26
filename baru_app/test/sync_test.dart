import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/local_store.dart';
import 'package:baru_app/data/repositories.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sincronização por domínio.
///
/// A regra que estes testes protegem: **o app pode falhar em sincronizar, mas
/// nunca pode esquecer que precisa sincronizar**. Perder a intenção é perder
/// dado do usuário sem ninguém saber.

/// Espia as chamadas de push e falha sob comando.
class _Espiao implements PetRepository, SessionRepository, ShopRepository,
    SettingsRepository, TrialRepository {
  _Espiao(this.nome);

  final String nome;
  final List<String> chamadas = [];
  bool falha = false;

  @override
  Future<void> pushRemote() async {
    chamadas.add(nome);
    if (falha) throw StateError('rede fora ($nome)');
  }

  @override
  Future<void> pullRemote() async {}

  @override
  Future<void> saveLocal({
    Species? species,
    String? name,
    int? coat,
    int? leaves,
    String? lang,
    int? goal,
    int? avg,
    bool? evening,
    bool? missed,
    bool? usageAccess,
    bool? active,
    PayPlan? plan,
    DateTime? startedAt,
  }) async {}

  @override
  Future<void> appendLocal(SessionRecord record) async {}

  @override
  Future<void> saveOwnedLocal(List<String> owned, int leaves) async {}
}

class _Cenario {
  _Cenario() {
    repos = BaruRepositories(
      MemorySnapshotStore(),
      pet: pet,
      shop: shop,
      settings: settings,
      sessions: sessions,
      trial: trial,
    );
  }

  final pet = _Espiao('pet');
  final shop = _Espiao('shop');
  final settings = _Espiao('settings');
  final sessions = _Espiao('sessions');
  final trial = _Espiao('trial');
  late final BaruRepositories repos;
  final avisos = <String>[];

  AppState novoEstado() {
    final s = AppState(repos: repos, onSyncError: avisos.add);
    s.startCompanionship();
    return s;
  }

  void limpa() {
    for (final e in [pet, shop, settings, sessions, trial]) {
      e.chamadas.clear();
    }
  }
}

/// O persist é debounced em 280 ms; 450 dá folga sem deixar o teste lento.
Future<void> _esperaPersist() =>
    Future<void>.delayed(const Duration(milliseconds: 450));

void main() {
  test('mudança na loja empurra a loja', () async {
    final c = _Cenario();
    final s = c.novoEstado();
    c.limpa();

    s.leaves = 100;
    s.buy(shopItems.first);
    await _esperaPersist();

    expect(c.shop.chamadas, isNotEmpty);
  });

  test('falha num domínio não impede os outros de subirem', () async {
    final c = _Cenario();
    final s = c.novoEstado();
    c.pet.falha = true;
    c.limpa();

    // Marca pet e ajustes na mesma rodada.
    s.setName('Rio');
    s.pickDur(50);
    await _esperaPersist();

    expect(c.pet.chamadas, isNotEmpty, reason: 'tentou o pet');
    expect(
      c.settings.chamadas,
      isNotEmpty,
      reason: 'a falha do pet não pode abortar a fila inteira',
    );
  });

  test('domínio que falhou é tentado de novo na gravação seguinte', () async {
    final c = _Cenario();
    final s = c.novoEstado();
    c.pet.falha = true;
    c.limpa();

    s.setName('Rio');
    await _esperaPersist();
    expect(c.pet.chamadas.length, 1);

    // Mudança de outro domínio: o pet não mudou de novo, mas continua devendo.
    c.limpa();
    s.pickDur(90);
    await _esperaPersist();

    expect(
      c.pet.chamadas,
      isNotEmpty,
      reason: 'a intenção de sync tem de voltar para a máscara ao falhar — '
          'senão a mudança some sem ninguém saber',
    );
  });

  test('quando a rede volta, o pendente sobe e para de ser tentado', () async {
    final c = _Cenario();
    final s = c.novoEstado();
    c.pet.falha = true;
    c.limpa();

    s.setName('Rio');
    await _esperaPersist();

    c.pet.falha = false;
    c.limpa();
    s.retryPendingSync();
    await _esperaPersist();
    expect(c.pet.chamadas, isNotEmpty, reason: 'reenviou o pendente');

    // Agora que subiu, uma mudança de outro domínio não arrasta mais o pet.
    c.limpa();
    s.pickDur(25);
    await _esperaPersist();
    expect(
      c.pet.chamadas,
      isEmpty,
      reason: 'pendência quitada não pode ficar sendo reenviada para sempre',
    );
  });

  test('o aviso de falha sai uma vez por episódio, não por gravação', () async {
    final c = _Cenario();
    final s = c.novoEstado();
    c.pet.falha = true;

    s.setName('Rio');
    await _esperaPersist();
    s.setName('Toco');
    await _esperaPersist();
    s.setName('Nina');
    await _esperaPersist();

    expect(
      c.avisos.length,
      1,
      reason: 'offline, cada toque dispara o debounce; um SnackBar por toque '
          'seria enxurrada',
    );
  });

  test('o aviso volta a sair depois de a sincronização se recuperar', () async {
    final c = _Cenario();
    final s = c.novoEstado();

    c.pet.falha = true;
    s.setName('Rio');
    await _esperaPersist();
    expect(c.avisos.length, 1);

    c.pet.falha = false;
    s.retryPendingSync();
    await _esperaPersist();

    c.pet.falha = true;
    s.setName('Toco');
    await _esperaPersist();
    expect(c.avisos.length, 2, reason: 'novo episódio, novo aviso');
  });

  test('o snapshot local é salvo mesmo com o remoto fora do ar', () async {
    final c = _Cenario();
    final s = c.novoEstado();
    for (final e in [c.pet, c.shop, c.settings, c.sessions, c.trial]) {
      e.falha = true;
    }

    s.leaves = 100;
    s.buy(shopItems.first);
    await _esperaPersist();

    final salvo = await c.repos.loadSnapshot();
    expect(salvo, isNotNull);
    expect(
      salvo!.owned,
      contains(shopItems.first.id),
      reason: 'falha remota nunca pode apagar o que já está local',
    );
  });
}
