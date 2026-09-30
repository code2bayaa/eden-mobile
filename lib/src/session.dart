/// Who is signed in — nobody, a studio, or a person — kept in the device keystore between launches.
///
/// Viewers never sign in: the cinema is open. A studio JWT lives one hour and a person JWT twelve, both
/// absolute, so an expired stored token is thrown away on restore rather than tried.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  SessionController({required this.api, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final EdenApi api;
  final FlutterSecureStorage _storage;

  SignedIn? _current;
  SignedIn? get current => _current;
  SessionKind? get kind => _current?.kind;
  bool restoring = true;

  Future<void> restore() async {
    try {
      final raw = await _storage.read(key: Config.sessionKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final expires = DateTime.tryParse('${json['expires_at']}');
        if (expires != null && DateTime.now().isBefore(expires)) {
          _set(SignedIn(
            kind: SessionKind.values.byName('${json['kind']}'),
            token: '${json['token']}',
            expiresAt: expires,
          ));
        } else {
          await _storage.delete(key: Config.sessionKey);
        }
      }
    } catch (_) {
      await _storage.delete(key: Config.sessionKey);
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> signedIn(SignedIn session) async {
    _set(session);
    await _storage.write(
      key: Config.sessionKey,
      value: jsonEncode({
        'kind': session.kind.name,
        'token': session.token,
        'expires_at': session.expiresAt.toIso8601String(),
      }),
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_current?.kind == SessionKind.studio) await api.studioSignOut();
    await forget();
  }

  /// Drops the token without telling the server — for a 401, where there is nothing left to tell.
  Future<void> forget() async {
    _set(null);
    await _storage.delete(key: Config.sessionKey);
    notifyListeners();
  }

  void _set(SignedIn? session) {
    _current = session;
    api.token = session?.token;
  }
}
