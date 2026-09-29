import 'package:flutter_test/flutter_test.dart';
import 'package:securesphere/models/monitoring_event.dart';
import 'package:securesphere/models/threat_analysis_result.dart';
import 'package:securesphere/services/local_threat_analyzer.dart';

void main() {
  group('Module 3: LocalThreatAnalyzer Tests', () {
    late LocalThreatAnalyzer analyzer;

    setUp(() {
      analyzer = LocalThreatAnalyzer();
    });

    test('TEST 1: Normal SMS returns LOW risk', () async {
      final event = MonitoringEvent(
        id: 'test-1',
        type: MonitoringEventType.sms,
        source: 'Hi Dad, can you pick up some groceries on your way home?',
        timestamp: DateTime.now(),
        status: MonitoringEventStatus.queued,
        metadata: {'text': 'Hi Dad, can you pick up some groceries on your way home?'},
      );

      final result = await analyzer.analyze(event);

      expect(result.riskLevel, equals(ThreatRiskLevel.low));
      expect(result.riskScore, lessThan(40));
      expect(result.title, contains('Normal'));
      expect(result.indicators, isNotEmpty);
      expect(result.recommendedAction, isNotEmpty);
    });

    test('TEST 2: SMS requesting OTP returns HIGH risk', () async {
      final event = MonitoringEvent(
        id: 'test-2',
        type: MonitoringEventType.sms,
        source: 'ALERT: Your SBI bank account will be blocked today. Please share the 6-digit OTP sent to your phone immediately to verify your KYC: bit.ly/sbi-verify',
        timestamp: DateTime.now(),
        status: MonitoringEventStatus.queued,
        metadata: {
          'text': 'ALERT: Your SBI bank account will be blocked today. Please share the 6-digit OTP sent to your phone immediately to verify your KYC: bit.ly/sbi-verify',
        },
      );

      final result = await analyzer.analyze(event);

      expect(result.riskLevel, equals(ThreatRiskLevel.high));
      expect(result.riskScore, greaterThanOrEqualTo(70));
      expect(result.title, contains('Scam'));
      expect(result.indicators.any((i) => i.toLowerCase().contains('otp')), isTrue);
      expect(result.recommendedAction, contains('OTP'));
    });

    test('TEST 3: Suspicious URL returns HIGH risk', () async {
      final event = MonitoringEvent(
        id: 'test-3',
        type: MonitoringEventType.url,
        source: 'http://192.168.1.1/login-secure-banking-verify-otp.xyz/account',
        timestamp: DateTime.now(),
        status: MonitoringEventStatus.queued,
        metadata: {'url': 'http://192.168.1.1/login-secure-banking-verify-otp.xyz/account'},
      );

      final result = await analyzer.analyze(event);

      expect(result.riskLevel, equals(ThreatRiskLevel.high));
      expect(result.riskScore, greaterThanOrEqualTo(70));
      expect(result.title, contains('Dangerous Link'));
      expect(result.indicators, isNotEmpty);
      expect(result.recommendedAction, isNotEmpty);
    });

    test('TEST 4: Normal URL returns LOW risk', () async {
      final event = MonitoringEvent(
        id: 'test-4',
        type: MonitoringEventType.url,
        source: 'https://www.google.com',
        timestamp: DateTime.now(),
        status: MonitoringEventStatus.queued,
        metadata: {'url': 'https://www.google.com'},
      );

      final result = await analyzer.analyze(event);

      expect(result.riskLevel, equals(ThreatRiskLevel.low));
      expect(result.riskScore, lessThan(40));
      expect(result.title, contains('Safe'));
    });

    test('TEST 5: Unknown application event returns MEDIUM risk', () async {
      final event = MonitoringEvent(
        id: 'test-5',
        type: MonitoringEventType.app,
        source: "App installed from unknown download source requesting SMS and Contacts permission: 'FreeLoansFast.apk'",
        timestamp: DateTime.now(),
        status: MonitoringEventStatus.queued,
        metadata: {'appName': 'FreeLoansFast.apk'},
      );

      final result = await analyzer.analyze(event);

      expect(result.riskLevel, anyOf(equals(ThreatRiskLevel.medium), equals(ThreatRiskLevel.high)));
      expect(result.riskScore, greaterThanOrEqualTo(40));
      expect(result.indicators, isNotEmpty);
    });
  });
}
