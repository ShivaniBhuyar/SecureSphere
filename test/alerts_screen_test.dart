import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securesphere/screens/alerts_screen.dart';
import 'package:securesphere/services/alert_service.dart';
import 'package:securesphere/theme/app_theme.dart';
import 'package:securesphere/models/monitoring_event.dart';
import 'package:securesphere/models/threat_analysis_result.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AlertService.autoSyncBackend = false;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createTestWidget(AlertService alertService) {
    return ChangeNotifierProvider<AlertService>.value(
      value: alertService,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AlertsScreen(),
      ),
    );
  }

  group('Module 5: AlertsScreen UI & Alert Center Tests', () {
    testWidgets('Renders Safety Alerts header, filter chips, and seeded cards', (tester) async {
      final service = AlertService();
      await service.ensureInitialized();

      await tester.pumpWidget(createTestWidget(service));
      await tester.pumpAndSettle();

      expect(find.text('Safety Alerts'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Unread ('), findsOneWidget);
      expect(find.textContaining('High ('), findsOneWidget);
      expect(find.textContaining('Medium ('), findsOneWidget);
      expect(find.textContaining('Low ('), findsOneWidget);
    });

    testWidgets('Tapping High filter chip shows only high risk alerts', (tester) async {
      final service = AlertService();
      await service.ensureInitialized();
      await service.clearAll();

      final highThreat = ThreatAnalysisResult(
        id: 't-high-1',
        eventId: 'e-1',
        eventType: MonitoringEventType.sms,
        riskScore: 92,
        riskLevel: ThreatRiskLevel.high,
        title: 'Critical Smishing Threat',
        summary: 'Demands ATM PIN to unblock debit card.',
        indicators: ['ATM PIN demand', 'Urgency trigger'],
        recommendedAction: 'Do not share card details.',
        timestamp: DateTime.now(),
      );

      final lowThreat = ThreatAnalysisResult(
        id: 't-low-1',
        eventId: 'e-2',
        eventType: MonitoringEventType.url,
        riskScore: 10,
        riskLevel: ThreatRiskLevel.low,
        title: 'Normal Safe Link',
        summary: 'Official government portal verified.',
        indicators: ['Verified domain'],
        recommendedAction: 'Safe to open.',
        timestamp: DateTime.now(),
      );

      await service.createAlertFromThreat(
        highThreat,
        triggerNotification: false,
        syncWithBackend: false,
      );
      await service.createAlertFromThreat(
        lowThreat,
        triggerNotification: false,
        syncWithBackend: false,
      );

      await tester.pumpWidget(createTestWidget(service));
      await tester.pumpAndSettle();

      expect(find.text('Critical Smishing Threat'), findsOneWidget);
      expect(find.text('Normal Safe Link'), findsOneWidget);

      // Tap 'High' filter chip
      await tester.tap(find.textContaining('High (1)'));
      await tester.pumpAndSettle();

      // Only high risk alert is displayed
      expect(find.text('Critical Smishing Threat'), findsOneWidget);
      expect(find.text('Normal Safe Link'), findsNothing);
    });

    testWidgets('Tapping an alert card opens bottom sheet with details & action', (tester) async {
      final service = AlertService();
      await service.ensureInitialized();
      await service.clearAll();

      final threat = ThreatAnalysisResult(
        id: 't-detail-1',
        eventId: 'e-detail-1',
        eventType: MonitoringEventType.app,
        riskScore: 85,
        riskLevel: ThreatRiskLevel.high,
        title: 'Malware Dropper Detected',
        summary: 'Trojan application masquerading as system update.',
        indicators: ['Unknown APK signature', 'Stealth background service'],
        recommendedAction: 'Uninstall immediately via Settings.',
        timestamp: DateTime.now(),
      );

      await service.createAlertFromThreat(
        threat,
        triggerNotification: false,
        syncWithBackend: false,
      );

      await tester.pumpWidget(createTestWidget(service));
      await tester.pumpAndSettle();

      // Tap on the card
      await tester.tap(find.text('Malware Dropper Detected'));
      await tester.pumpAndSettle();

      // Detailed modal opens
      expect(find.text('IMMEDIATE ATTENTION REQUIRED'), findsOneWidget);
      expect(find.text('THREAT ANALYSIS REASON'), findsOneWidget);
      expect(find.text('DETECTED THREAT INDICATORS'), findsOneWidget);
      expect(find.text('Unknown APK signature'), findsOneWidget);
      expect(find.text('RECOMMENDED SECURITY ACTION'), findsOneWidget);
      expect(find.text('Uninstall immediately via Settings.'), findsOneWidget);
    });

    testWidgets('Empty state is shown when no alerts match filter', (tester) async {
      final service = AlertService();
      await service.ensureInitialized();
      await service.clearAll();

      await tester.pumpWidget(createTestWidget(service));
      await tester.pumpAndSettle();

      expect(find.text('No Security Alerts'), findsOneWidget);
      expect(find.textContaining('No threats matching your current filter'), findsOneWidget);
    });
  });
}
