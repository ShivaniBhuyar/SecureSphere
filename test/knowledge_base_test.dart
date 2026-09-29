import 'package:flutter_test/flutter_test.dart';
import 'package:securesphere/models/knowledge_entry.dart';
import 'package:securesphere/models/monitoring_event.dart';
import 'package:securesphere/models/threat_analysis_result.dart';
import 'package:securesphere/services/knowledge_repository.dart';

void main() {
  group('Module 4: KnowledgeData & KnowledgeRepository Unit Tests', () {
    late KnowledgeRepository repository;

    setUp(() {
      repository = KnowledgeRepository();
    });

    test('All knowledge base entries have valid required fields', () {
      final entries = repository.getAllEntries();
      expect(entries, isNotEmpty);
      expect(entries.length, greaterThanOrEqualTo(10));

      for (final entry in entries) {
        expect(entry.id, isNotEmpty);
        expect(entry.title, isNotEmpty);
        expect(entry.description, isNotEmpty);
        expect(entry.howScammersDoIt, isNotEmpty);
        expect(entry.warningSigns, isNotEmpty);
        expect(entry.recommendedActions, isNotEmpty);
        expect(entry.preventionTips, isNotEmpty);
        expect(entry.keywords, isNotEmpty);
      }
    });

    test('All 8 required knowledge categories are represented in the dataset', () {
      final entries = repository.getAllEntries();
      final presentCategories = entries.map((e) => e.category).toSet();

      for (final category in KnowledgeCategory.values) {
        expect(
          presentCategories.contains(category),
          isTrue,
          reason: 'Category ${category.label} should have at least one knowledge entry',
        );
      }
    });

    test('Search filters correctly by keywords and text', () {
      // Test 1: Search 'OTP'
      final otpResults = repository.search('OTP');
      expect(otpResults, isNotEmpty);
      expect(otpResults.any((e) => e.id == 'otp_scam'), isTrue);

      // Test 2: Search 'UPI'
      final upiResults = repository.search('UPI');
      expect(upiResults, isNotEmpty);
      expect(upiResults.any((e) => e.id == 'upi_scam'), isTrue);

      // Test 3: Search 'phishing'
      final phishingResults = repository.search('phishing');
      expect(phishingResults, isNotEmpty);
      expect(phishingResults.any((e) => e.id == 'phishing_links'), isTrue);

      // Test 4: Search 'password'
      final passwordResults = repository.search('password');
      expect(passwordResults, isNotEmpty);
      expect(passwordResults.any((e) => e.id == 'password_security'), isTrue);

      // Test 5: Search 'malware' or 'apk'
      final apkResults = repository.search('apk');
      expect(apkResults, isNotEmpty);
      expect(apkResults.any((e) => e.id == 'fake_apps'), isTrue);
    });

    test('Search with category filter respects category constraints', () {
      final paymentEntries = repository.search('', category: KnowledgeCategory.paymentSafety);
      expect(paymentEntries, isNotEmpty);
      expect(paymentEntries.every((e) => e.category == KnowledgeCategory.paymentSafety), isTrue);

      final linkEntries = repository.search('', category: KnowledgeCategory.safeLinks);
      expect(linkEntries, isNotEmpty);
      expect(linkEntries.every((e) => e.category == KnowledgeCategory.safeLinks), isTrue);
    });

    test('Search with non-existent keyword returns empty list', () {
      final emptyResults = repository.search('xyznonexistentquery12345');
      expect(emptyResults, isEmpty);
    });

    test('Module 3 to Module 4: findRelevantKnowledge matches SMS OTP threat', () {
      final threat = ThreatAnalysisResult(
        id: 'test-otp-threat',
        eventId: 'event-1',
        eventType: MonitoringEventType.sms,
        riskScore: 85,
        riskLevel: ThreatRiskLevel.high,
        title: 'Possible Scam Message Detected',
        summary: 'This message asks for a 6-digit OTP verification code.',
        indicators: ['The message asks for a secret OTP or verification code.'],
        recommendedAction: 'Never share any OTP or password with anyone.',
        timestamp: DateTime(2026, 1, 1),
      );

      final matchedEntry = repository.findRelevantKnowledge(threat);
      expect(matchedEntry.id, equals('otp_scam'));
      expect(matchedEntry.category, equals(KnowledgeCategory.paymentSafety));
    });

    test('Module 3 to Module 4: findRelevantKnowledge matches Suspicious URL threat', () {
      final threat = ThreatAnalysisResult(
        id: 'test-url-threat',
        eventId: 'event-2',
        eventType: MonitoringEventType.url,
        riskScore: 90,
        riskLevel: ThreatRiskLevel.high,
        title: 'Dangerous Phishing Link Detected',
        summary: 'This website attempts to mimic an official bank login.',
        indicators: ['The URL uses .xyz domain to impersonate banking login.'],
        recommendedAction: 'Do not enter passwords or card details on this website.',
        timestamp: DateTime(2026, 1, 1),
      );

      final matchedEntry = repository.findRelevantKnowledge(threat);
      expect(matchedEntry.id, equals('phishing_links'));
      expect(matchedEntry.category, equals(KnowledgeCategory.safeLinks));
    });

    test('Module 3 to Module 4: findRelevantKnowledge matches APK / Fake App threat', () {
      final threat = ThreatAnalysisResult(
        id: 'test-app-threat',
        eventId: 'event-3',
        eventType: MonitoringEventType.app,
        riskScore: 70,
        riskLevel: ThreatRiskLevel.medium,
        title: 'Potentially Harmful Application',
        summary: 'Application installed from unknown source requesting SMS permissions.',
        indicators: ['Side-loaded APK requesting high-risk SMS permissions.'],
        recommendedAction: 'Uninstall the unverified application immediately.',
        timestamp: DateTime(2026, 1, 1),
      );

      final matchedEntry = repository.findRelevantKnowledge(threat);
      expect(matchedEntry.id, equals('fake_apps'));
      expect(matchedEntry.category, equals(KnowledgeCategory.mobileSafety));
    });
  });
}
