import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securesphere/services/api_service.dart';
import 'package:securesphere/services/knowledge_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Online Architecture: ApiService & Online Repository Tests', () {
    late ApiService apiService;
    late KnowledgeRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      apiService = ApiService();
      repository = KnowledgeRepository();
    });

    test('ApiService initializes with default base URL', () {
      expect(apiService.baseUrl, isNotEmpty);
      expect(apiService.baseUrl, contains('http'));
    });

    test('ApiService can update base URL', () async {
      await apiService.setBaseUrl('http://192.168.1.100:8000/');
      expect(apiService.baseUrl, equals('http://192.168.1.100:8000'));
    });

    test('KnowledgeRepository falls back to local data if offline', () async {
      // Set to an unreachable URL to test fallback resilience
      await apiService.setBaseUrl('http://127.0.0.1:59999');

      final entries = repository.getAllEntries();
      expect(entries, isNotEmpty);

      // Search fallback
      final searchResults = await repository.searchOnlineOrOffline('OTP');
      expect(searchResults, isNotEmpty);
      expect(searchResults.any((e) => e.id == 'otp_scam'), isTrue);

      // Refresh should return false but not throw or crash
      final refreshed = await repository.refreshFromOnline();
      expect(refreshed, isFalse);
      expect(repository.getAllEntries(), isNotEmpty);
    });

    test('ApiService checkHealth returns false gracefully on unreachable host', () async {
      await apiService.setBaseUrl('http://127.0.0.1:59999');
      final isOnline = await apiService.checkHealth(
        timeout: const Duration(milliseconds: 300),
      );
      expect(isOnline, isFalse);
    });
  });
}
