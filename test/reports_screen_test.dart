import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securesphere/screens/reports_screen.dart';
import 'package:securesphere/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createTestWidget() {
    return MaterialApp(theme: AppTheme.darkTheme, home: const ReportsScreen());
  }

  group('Module 7: ReportsScreen UI & Analytics Tests', () {
    testWidgets('Renders Reports & Analytics header and all 4 tabs', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Reports & Analytics'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Device Score'), findsOneWidget);
      expect(find.text('Threat History'), findsOneWidget);
      expect(find.text('Trends & Insights'), findsOneWidget);
    });

    testWidgets('Overview tab displays security posture card and metrics', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('OVERALL SECURITY POSTURE'), findsOneWidget);
      expect(find.text('Security Metrics'), findsOneWidget);
      expect(find.text('High Risk Events'), findsOneWidget);
      expect(find.text('Medium Risks'), findsOneWidget);
      expect(find.text('Safe Checks'), findsOneWidget);
      expect(find.text('Peak Risk Score'), findsOneWidget);
      expect(find.text('Recommended Protective Actions'), findsOneWidget);
    });

    testWidgets('Tapping timeframe chips updates selection', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();

      // Ensure widget didn't crash and remains stable
      expect(find.text('Reports & Analytics'), findsOneWidget);
    });

    testWidgets(
      'Switching to Device Score tab renders score gauge and factors',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Device Score'));
        await tester.pumpAndSettle();

        expect(find.text('SecureSphere Device Security Score'), findsOneWidget);
        expect(find.text('Evaluated Security Factors'), findsOneWidget);
        expect(find.text('Operating System Integrity'), findsOneWidget);
      },
    );

    testWidgets(
      'Switching to Threat History tab displays filter chips and records',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Threat History'));
        await tester.pumpAndSettle();

        expect(find.text('ALL'), findsOneWidget);
        expect(find.text('SMS'), findsOneWidget);
        expect(find.text('URL'), findsOneWidget);
        expect(find.text('APP'), findsOneWidget);
        expect(find.text('EMAIL'), findsOneWidget);
        expect(find.text('DEVICE'), findsOneWidget);
      },
    );

    testWidgets(
      'Switching to Trends & Insights tab renders bar chart and insights',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Trends & Insights'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Activity Trends'), findsOneWidget);
        expect(find.text('Daily Threat Scans'), findsOneWidget);
        expect(find.text('Risk Severity Distribution'), findsOneWidget);
        expect(find.text('Automated Security Insights'), findsOneWidget);
      },
    );

    testWidgets('Tapping Export icon opens security digest dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final exportButton = find.byTooltip('Export Summary');
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(find.text('Security Digest'), findsOneWidget);
      expect(find.text('COPY DIGEST'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.text('Security Digest'), findsNothing);
    });
  });
}
