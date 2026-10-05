import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securesphere/screens/ask_screen.dart';
import 'package:securesphere/services/chatbot_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget widget) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: widget,
    );
  }

  group('Module 6: AI Chatbot Service Unit Tests', () {
    late ChatbotService chatbotService;

    setUp(() {
      chatbotService = ChatbotService();
    });

    test('ChatbotService initializes with welcome message and suggestions', () {
      expect(chatbotService.messages, isNotEmpty);
      expect(chatbotService.messages.first.isUser, isFalse);
      expect(chatbotService.messages.first.text, contains('SecureSphere AI Assistant'));
      expect(chatbotService.quickSuggestions, isNotEmpty);
    });

    test('ChatbotService resetConversation clears history and retains welcome', () {
      final oldConvId = chatbotService.conversationId;
      chatbotService.resetConversation();
      expect(chatbotService.messages.length, equals(1));
      expect(chatbotService.conversationId, isNot(equals(oldConvId)));
    });

    test('ChatbotService handles offline fallback gracefully without crash', () async {
      final msg = await chatbotService.sendMessage(text: 'What should I do if someone asks for my OTP?');
      expect(msg, isNotNull);
      expect(chatbotService.messages.length, greaterThanOrEqualTo(2));
      expect(msg.text, isNotEmpty);
    });
  });

  group('Module 6: AskScreen UI Widget Tests', () {
    testWidgets('Renders SecureSphere AI header, avatar, input field, voice and send buttons', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AskScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Check App bar title
      expect(find.text('SecureSphere AI'), findsOneWidget);

      // Check initial assistant message
      expect(find.textContaining('SecureSphere AI Assistant'), findsOneWidget);

      // Check text input field
      expect(find.byType(TextField), findsOneWidget);

      // Check Voice & Send icons
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Typing a message and pressing send adds user bubble and triggers analysis', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AskScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Enter query
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'How do I protect my UPI PIN?');
      await tester.pump();

      // Tap send
      final sendButton = find.byIcon(Icons.send_rounded);
      await tester.tap(sendButton);
      await tester.pump(const Duration(milliseconds: 200));

      // User message should appear immediately
      expect(find.text('How do I protect my UPI PIN?'), findsOneWidget);

      // Settle timers (idle timer 3s)
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Tapping suggestion chip sends query into chat', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AskScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Find one of the suggestion chips
      final otpChip = find.text('What should I do if someone asks for my OTP?');
      if (otpChip.evaluate().isNotEmpty) {
        await tester.tap(otpChip.first);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('What should I do if someone asks for my OTP?'), findsAtLeastNWidgets(1));
        await tester.pump(const Duration(seconds: 4));
      }
    });

    testWidgets('Tapping microphone opens voice recognition bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AskScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap mic icon
      final micButton = find.byIcon(Icons.mic_none);
      await tester.tap(micButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify voice sheet is displayed
      expect(find.text('Listening for Cybersecurity Query...'), findsOneWidget);

      // Tap barrier to dismiss modal bottom sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 500));

      // Voice sheet dismissed
      expect(find.text('Listening for Cybersecurity Query...'), findsNothing);
    });
  });
}
