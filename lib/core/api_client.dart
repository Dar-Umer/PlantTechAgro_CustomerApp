import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Thrown for API-level failures so UI can show a friendly message.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  /// First validation message, if the backend returned 422 errors.
  String? get firstFieldError {
    final errs = errors;
    if (errs == null) return null;
    for (final value in errs.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String) return value;
    }
    return null;
  }

  bool get isRateLimited => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;

  /// User-facing message: friendly rate-limit copy per the UI spec,
  /// otherwise the first field error or the server message.
  String get friendlyMessage {
    if (isRateLimited) {
      return 'Too many attempts. Please wait a minute before trying again.';
    }
    return firstFieldError ?? message;
  }
}

/// Persists the Sanctum token + cached user payload.
class SessionStore {
  static const _kToken = 'pta.auth.token';
  static const _kUser = 'pta.auth.user';

  String? token;
  Map<String, dynamic>? user;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kToken);
    final raw = prefs.getString(_kUser);
    if (raw != null && raw.isNotEmpty) {
      try {
        user = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        user = null;
      }
    }
  }

  Future<void> save(String token, Map<String, dynamic> user) async {
    this.token = token;
    this.user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user));
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    this.user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user));
  }

  Future<void> clear() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}

/// Thin wrapper over `package:http` that injects the bearer token,
/// encodes JSON, and converts Laravel error shapes into [ApiException].
class ApiClient {
  ApiClient(this.session);
  final SessionStore session;

  /// Fired (once per response) on HTTP 401 so the app can flush the
  /// session and return to Login (spec §5). Set from main.dart.
  Future<void> Function()? onUnauthorized;

  Map<String, String> get _headers {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final t = session.token;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final clean = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('${ApiConfig.baseUrl}$clean');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        for (final e in query.entries)
          if (e.value != null) e.key: e.value.toString(),
      },
    );
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? {} : jsonDecode(res.body);
    } catch (_) {
      body = {'message': res.body};
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final msg = (map['message'] ?? 'Request failed (${res.statusCode}).').toString();
    final errors = map['errors'] is Map<String, dynamic>
        ? map['errors'] as Map<String, dynamic>
        : null;
    final err = ApiException(msg, statusCode: res.statusCode, errors: errors);
    if (err.isUnauthorized) {
      final hook = onUnauthorized;
      if (hook != null) Future.microtask(hook);
    }
    throw err;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? data]) async {
    final res = await http.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(data ?? {}),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? data]) async {
    final res = await http.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(data ?? {}),
    );
    return _decode(res);
  }
}
