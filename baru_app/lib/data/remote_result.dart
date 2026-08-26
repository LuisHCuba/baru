import 'app_snapshot.dart';

/// Resultado de pull/push remoto — nunca falha silenciosamente no gate.
class RemotePullResult {
  const RemotePullResult({this.snapshot, this.error});

  final AppSnapshot? snapshot;
  final String? error;

  bool get ok => error == null;
  bool get isNewAccount => snapshot == null && error == null;
}

class RemotePushResult {
  const RemotePushResult({this.ok = true, this.error});

  final bool ok;
  final String? error;
}
