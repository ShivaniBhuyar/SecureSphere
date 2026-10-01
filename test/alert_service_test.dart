import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securesphere/models/security_alert.dart';
import 'package:securesphere/models/threat_analysis_result.dart';
import 'package:securesphere/models/monitoring_event.dart';
import 'package:securesphere/services/alert_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Module 5: SecurityAlert Model Unit Tests', () {
    test('Converts ThreatAnalysisResult into SecurityAlert correctly', () {
      final now = DateTime.now();
      final threat = ThreatAnalysisResult(
        id: 'threat-101',
        eventId: 'event-101',
        eventType: MonitoringEventType.sms,
        riskScore: 89,
        riskLevel: ThreatRiskLevel.high,
        title: 'SMS Threat Detected',
        summary: 'Message requested an immediate OTP to avoid bank account blockage.',
        indicators: [
          'The message asks for an OTP',
          'It creates false urgency',
        ],
        recommendedAction: 'Do not share your OTP.',
        timestamp: now,
      );

      final alert = SecurityAlert.fromThreatResult(threat);

      expect(alert.id, equals('threat-101'));
      expect(alert.threatId, equals('threat-101'));
      expect(alert.threatType, equals('sms_threat'));
      expect(alert.riskLevel, equals(ThreatRiskLevel.high));
      expect(alert.riskScore, equals(89));
      expect(alert.isHighRisk, isTrue);
      expect(alert.isRead, isFalse);
      expect(alert.indicators.length, equals(2));
      expect(alert.recommendedAction, equals('Do not share your OTP.'));
      expect(alert.severityLabel, equals('HIGH'));
    });

    test('Serializes and deserializes SecurityAlert to and from JSON', () {
      final now = DateTime.now();
      final original = SecurityAlert(
        id: 'alert-json-1',
        threatId: 'threat-json-1',
        threatType: 'url_threat',
        riskLevel: ThreatRiskLevel.medium,
        riskScore: 55,
        confidence: 0.85,
        title: 'Suspicious Link Warning',
        reason: 'Unverified short link detected.',
        indicators: ['Shortened bit.ly URL', 'Unknown sender domain'],
        recommendedAction: 'Do not click the link.',
        timestamp: now,
        isRead: true,
      );

      final json = original.toJson();
      final reconstructed = SecurityAlert.fromJson(json);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.threatType, equals(original.threatType));
      expect(reconstructed.riskLevel, equals(ThreatRiskLevel.medium));
      expect(reconstructed.riskScore, equals(55));
      expect(reconstructed.isRead, isTrue);
      expect(reconstructed.indicators.length, equals(2));
      expect(reconstructed.reason, equals(original.reason));
    });
  });

  group('Module 5: AlertService Business Logic & Deduplication Tests', () {
    test('AlertService creates alerts and updates unread count', () async {
      final service = AlertService();
      await service.clearAll();

      final threat = ThreatAnalysisResult(
        id: 't-unique-1',
        eventId: 'e-unique-1',
        eventType: MonitoringEventType.app,
        riskScore: 60,
        riskLevel: ThreatRiskLevel.medium,
        title: 'Unknown App Warning',
        summary: 'App requested SMS and location permissions.',
        indicators: ['Unverified app store source'],
        recommendedAction: 'Check app permissions.',
        timestamp: DateTime.now(),
      );

      final alert = await service.createAlertFromThreat(
        threat,
        triggerNotification: false,
      );

      expect(alert, isNotNull);
      expect(service.alerts.length, equals(1));
      expect(service.unreadCount, equals(1));
      expect(service.mediumRiskAlerts.length, equals(1));
      expect(service.highRiskAlerts.length, equals(0));
    });

    test('Duplicate Alert Prevention: Rejects identical threat within dedup window', () async {
      final service = AlertService();
      await service.clearAll();

      final threat = ThreatAnalysisResult(
        id: 't-dedup-1',
        eventId: 'e-dedup-1',
        eventType: MonitoringEventType.sms,
        riskScore: 90,
        riskLevel: ThreatRiskLevel.high,
        title: 'Banking Smishing Alert',
        summary: 'Repeated SMS requesting OTP from same spoofed sender.',
        indicators: ['Demands OTP', 'False bank domain'],
        recommendedAction: 'Block immediately.',
        timestamp: DateTime.now(),
      );

      // First call -> creates alert
      final alert1 = await service.createAlertFromThreat(
        threat,
        triggerNotification: false,
      );
      expect(alert1, isNotNull);
      expect(service.alerts.length, equals(1));

      // Second call immediately with same threat event and summary
      final alert2 = await service.createAlertFromThreat(
        threat,
        triggerNotification: false,
      );

      // Should return the existing alert without inserting a duplicate!
      expect(service.alerts.length, equals(1));
      expect(alert2?.id, equals(alert1?.id));
    });

    test('Read/Unread status management', () async {
      final service = AlertService();
      await service.clearAll();

      final threat1 = ThreatAnalysisResult(
        id: 't-read-1',
        eventId: 'e-read-1',
        eventType: MonitoringEventType.url,
        riskScore: 85,
        riskLevel: ThreatRiskLevel.high,
        title: 'Phishing URL',
        summary: 'Deceptive domain pretending to be banking portal.',
        indicators: ['Punycode character spoofing'],
        recommendedAction: 'Close browser tab.',
        timestamp: DateTime.now(),
      );

      final threat2 = ThreatAnalysisResult(
        id: 't-read-2',
        eventId: 'e-read-2',
        eventType: MonitoringEventType.device,
        riskScore: 20,
        riskLevel: ThreatRiskLevel.low,
        title: 'Device Verified',
        summary: 'Screen lock is securely enabled.',
        indicators: ['PIN security verified'],
        recommendedAction: 'No action required.',
        timestamp: DateTime.now(),
      );

      await service.createAlertFromThreat(threat1, triggerNotification: false);
      await service.createAlertFromThreat(threat2, triggerNotification: false);

      expect(service.alerts.length, equals(2));
      expect(service.unreadCount, equals(2));

      // Mark single alert as read
      await service.markAsRead('t-read-1');
      expect(service.unreadCount, equals(1));

      // Mark as unread
      await service.markAsUnread('t-read-1');
      expect(service.unreadCount, equals(2));

      // Mark all as read
      await service.markAllAsRead();
      expect(service.unreadCount, equals(0));
      expect(service.unreadAlerts.length, equals(0));
    });

    test('Deleting an alert removes it from history', () async {
      final service = AlertService();
      await service.clearAll();

      final threat = ThreatAnalysisResult(
        id: 't-del-1',
        eventId: 'e-del-1',
        eventType: MonitoringEventType.sms,
        riskScore: 75,
        riskLevel: ThreatRiskLevel.high,
        title: 'Test Delete Alert',
        summary: 'Temporary threat for deletion test.',
        indicators: ['Test indicator'],
        recommendedAction: 'Test action',
        timestamp: DateTime.now(),
      );

      await service.createAlertFromThreat(threat, triggerNotification: false);
      expect(service.alerts.length, equals(1));

      await service.deleteAlert('t-del-1');
      expect(service.alerts.length, equals(0));
    });
  });
}
