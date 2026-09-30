/// The one HTTP client, and every Eden call the app makes.
///
/// Every request goes through the backend's mobile entry: `x-eden-client: mobile` skips the browser and
/// origin checks, `x-api-key` carries the mobile key, and the session JWT rides as `Authorization:
/// Bearer` (the backend files it into the cookie slot the web app would have used).
///
/// The backend answers `{status, message, data}` and often says no with HTTP 200 + `status: false`, so
/// [_unwrap] treats `status` as the truth and the HTTP code only as a hint.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.unauthorized = false});
  final String message;
  final bool unauthorized;
  @override
  String toString() => message;
}

class EdenApi {
  EdenApi({http.Client? client, this.onUnauthorized}) : _http = client ?? http.Client();

  final http.Client _http;

  /// A 401 from a signed-in call: the JWT has run out (studio 1 h, person 12 h).
  final void Function()? onUnauthorized;

  String? token;

  static const _timeout = Duration(seconds: 20);

  Map<String, String> get _headers => {
        'x-eden-client': 'mobile',
        'x-api-key': Config.mobileKey,
        'content-type': 'application/json',
        'accept': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${Config.apiBase}$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send(() => _http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? const {})));

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Eden is taking too long to answer. Check your connection.');
    } catch (_) {
      throw ApiException('Could not reach Eden. Check your connection.');
    }
    return _unwrap(res);
  }

  Map<String, dynamic> _unwrap(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      body = const {};
    }
    final message = '${body['message'] ?? body['error'] ?? ''}'.trim();

    if (res.statusCode == 401) {
      if (token != null) onUnauthorized?.call();
      throw ApiException('Your session has ended. Sign in again.', unauthorized: true);
    }
    if (res.statusCode == 403 && message == 'Invalid API Key') {
      throw ApiException('This build has no valid EDEN_MOBILE_KEY.');
    }
    if (res.statusCode >= 400 || body['status'] == false) {
      throw ApiException(message.isEmpty ? 'Eden said no (HTTP ${res.statusCode}).' : message);
    }
    return body;
  }

  // ------------------------------------------------------------------ cinema (no session)

  Future<CinemaPage> cinema({int page = 1, int limit = 20}) async {
    final body = await get('/cinema', query: {'page': '$page', 'limit': '$limit'});
    return CinemaPage.fromJson(body);
  }

  Future<List<StudioCard>> cinemaStudios() async {
    final body = await get('/cinema/studios');
    return [for (final s in (body['data'] as List? ?? const [])) StudioCard.fromJson(s as Map)];
  }

  final _posters = <String, Uint8List>{};

  /// Poster bytes, proxied from B2 by `/cinema/poster`. Kept for the life of the process so a scroll
  /// back up does not ask again.
  Future<Uint8List?> poster(String image) async {
    final cached = _posters[image];
    if (cached != null) return cached;
    try {
      final res = await _http
          .post(_uri('/cinema/poster'), headers: _headers, body: jsonEncode({'image': image}))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return _posters[image] = res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------ studio

  /// Returns the JWT; the caller stores it.
  Future<SignedIn> studioSignIn(String telephone, String password) async {
    final body = await post('/signin', {'telephone': telephone, 'password': password});
    return SignedIn.fromJson(body, SessionKind.studio);
  }

  Future<StudioProfile> studioProfile() async {
    final body = await get('/profile');
    return StudioProfile.fromJson((body['data'] as Map).cast<String, dynamic>());
  }

  /// Starts an M-PESA B2C payout. `socket_key` is the relay room the backend listens on for Daraja's
  /// result — the app never joins it, it polls [withdrawal] instead.
  Future<Withdrawal> withdraw(int amount) async {
    final body = await post('/withdraw', {'amount': amount, 'socket_key': _hex32()});
    return Withdrawal.fromJson((body['data'] as Map).cast<String, dynamic>());
  }

  Future<Withdrawal> withdrawal(int id) async {
    final body = await get('/withdraw/$id');
    return Withdrawal.fromJson((body['data'] as Map).cast<String, dynamic>());
  }

  /// Tells the PHP side the studio has left. The token itself is simply dropped by the app.
  Future<void> studioSignOut() async {
    try {
      await get('/signout');
    } catch (_) {}
  }

  // ------------------------------------------------------------------ person (cast & crew)

  Future<String> personRequestCode(String email) async {
    final body = await post('/person/signin', {'email': email});
    return '${body['message'] ?? 'Code sent'}';
  }

  Future<SignedIn> personConfirm(String email, String otp) async {
    final body = await post('/person/signin/confirm', {'email': email, 'otp': otp});
    return SignedIn.fromJson(body, SessionKind.person);
  }

  Future<PersonProfile> personProfile() async {
    final body = await get('/person/profile');
    return PersonProfile.fromJson((body['data'] as Map).cast<String, dynamic>());
  }

  Future<List<StudioCard>> personStudios() async {
    final body = await get('/person/studios');
    return [for (final s in (body['data'] as List? ?? const [])) StudioCard.fromJson(s as Map)];
  }

  void close() => _http.close();
}

String _hex32() {
  final r = Random.secure();
  return List.generate(32, (_) => r.nextInt(16).toRadixString(16)).join();
}
