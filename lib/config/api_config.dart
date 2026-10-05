/// Centralized API configuration for SecureSphere.
///
/// Supports:
/// - Compile-time production override: `--dart-define=API_BASE_URL=https://...`
/// - Public cloud backend default
/// - Local development loopback (USB/ADB reverse): `http://127.0.0.1:8000`
/// - Android emulator loopback: `http://10.0.2.2:8000`
class ApiConfig {
  /// Base URL provided at compile-time via `--dart-define=API_BASE_URL=https://...`
  static const String compileTimeBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Active public online HTTPS backend endpoint (deployed Render backend)
  static const String defaultOnlineUrl =
      'https://securesphere-api-lgdw.onrender.com';

  /// Standard cloud production domain (deployed Render backend)
  static const String defaultProductionUrl =
      'https://securesphere-api-lgdw.onrender.com';

  /// Local development loopback for ADB reverse or Desktop
  static const String localDevUrl = 'http://127.0.0.1:8000';

  /// Android emulator loopback to host PC
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';

  /// Determines the primary initial base URL.
  /// Priority order:
  /// 1. Compile-time `--dart-define=API_BASE_URL=...` (if passed)
  /// 2. Active public online HTTPS backend
  /// 3. Local development loopback fallback
  static String get initialBaseUrl {
    if (compileTimeBaseUrl.isNotEmpty) {
      return sanitizeUrl(compileTimeBaseUrl);
    }
    return defaultOnlineUrl;
  }

  /// Ordered list of candidate fallback URLs to probe when checking health.
  static List<String> get candidateUrls {
    final List<String> candidates = [];

    if (compileTimeBaseUrl.isNotEmpty) {
      candidates.add(sanitizeUrl(compileTimeBaseUrl));
    }
    candidates.addAll([
      defaultOnlineUrl,
      defaultProductionUrl,
      localDevUrl,
      'http://10.217.151.92:8000',
      androidEmulatorUrl,
      'http://localhost:8000',
    ]);

    // Deduplicate candidates preserving insertion order
    final seen = <String>{};
    return candidates.where((url) => seen.add(url)).toList();
  }

  /// Normalizes URLs by trimming whitespace and trailing slashes.
  static String sanitizeUrl(String url) {
    return url.trim().replaceAll(RegExp(r'/+$'), '');
  }
}
