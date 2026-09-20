/* Base-URL resolution for the PTA Laravel backend.
 *
 * Priority:
 * 1. `--dart-define=API_BASE_URL=https://example.com/api`
 * 2. Platform default (Android emulator cannot reach localhost directly).
 */
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defined = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// e.g. `http://10.0.2.2:8000/api` for the Android emulator,
  /// `http://localhost:8000/api` for desktop, web and iOS simulator.
  static String get baseUrl {
    if (_defined.isNotEmpty) return _defined.replaceAll(RegExp(r'/+$'), '');
    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  /// Storage base (file URLs like `/storage/...` are relative to host root).
  static String get hostRoot {
    final base = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return base;
  }

  /// Resolve a possibly-relative media path (`/storage/x.jpg` or full URL).
  static String? resolveMedia(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final root = hostRoot;
    if (path.startsWith('/')) return '$root$path';
    return '$root/$path';
  }
}
