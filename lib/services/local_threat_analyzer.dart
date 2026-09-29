import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';
import 'threat_analyzer.dart';

/// Local defensive rule-based threat analyzer for Module 3.
/// Performs offline, privacy-preserving threat analysis using beginner-friendly language.
class LocalThreatAnalyzer implements ThreatAnalyzer {
  static const _uuid = Uuid();

  @override
  Future<ThreatAnalysisResult> analyze(MonitoringEvent event) async {
    // Simulate lightweight AI analysis processing delay (1.2s)
    await Future.delayed(const Duration(milliseconds: 1200));

    switch (event.type) {
      case MonitoringEventType.sms:
        return _analyzeSms(event);
      case MonitoringEventType.url:
        return _analyzeUrl(event);
      case MonitoringEventType.app:
        return _analyzeApp(event);
      case MonitoringEventType.email:
        return _analyzeEmail(event);
      case MonitoringEventType.device:
        return _analyzeDevice(event);
    }
  }

  ThreatAnalysisResult _analyzeSms(MonitoringEvent event) {
    final text = _extractContent(event).toLowerCase();
    int score = 0;
    final List<String> indicators = [];

    // Rule 1: Request for OTP / PIN / Verification Code
    if (RegExp(r'\b(otp|one[-\s]?time[-\s]?password|verification[-\s]?code|pin|security[-\s]?code)\b').hasMatch(text)) {
      score += 35;
      indicators.add('The message asks for a secret OTP or verification code.');
    }

    // Rule 2: Request for Password / Credentials
    if (RegExp(r'\b(password|passcode|secret[-\s]?key|login[-\s]?details)\b').hasMatch(text)) {
      score += 35;
      indicators.add('The message asks for your password or secret login information.');
    }

    // Rule 3: Urgent payment or threat of account suspension
    if (RegExp(r'\b(blocked|suspended|deactivated|expire|urgent|immediately|within 24|act now|restricted)\b').hasMatch(text)) {
      score += 25;
      indicators.add('It creates false urgency by threatening that your account will be blocked.');
    }

    // Rule 4: Banking or KYC demand
    if (RegExp(r'\b(bank|kyc|pan[-\s]?card|aadhaar|debit[-\s]?card|credit[-\s]?card|cvv|account[-\s]?number)\b').hasMatch(text)) {
      score += 25;
      indicators.add('It mentions sensitive banking or KYC identity details.');
    }

    // Rule 5: Lottery / Prize / Money claim
    if (RegExp(r'\b(won|prize|lottery|reward|claim now|jackpot|free cash|bonus cash)\b').hasMatch(text)) {
      score += 30;
      indicators.add('It promises unexpected prizes or lottery money to lure you.');
    }

    // Rule 6: Suspicious link embedded
    if (RegExp(r'(http:\/\/|https:\/\/|bit\.ly|tinyurl|t\.co|goo\.gl|\.xyz|\.top|\.apk)').hasMatch(text)) {
      score += 25;
      indicators.add('It includes an unverified external website or short link.');
    }

    // Rule 7: Impersonation of official authority
    if (RegExp(r'\b(rbi|sbi|official|customer care|electricity board|tax department)\b').hasMatch(text)) {
      score += 15;
      indicators.add('It claims to be from an official organization or customer care.');
    }

    // Normal safe message checks
    if (indicators.isEmpty) {
      score = math.max(5, (text.length % 12)); // Low baseline 5-16
      indicators.add('Standard conversation message with no suspicious patterns.');
    }

    score = score.clamp(0, 100);
    final level = _classify(score);

    String title;
    String summary;
    String recommendedAction;

    if (level == ThreatRiskLevel.high) {
      title = 'Possible Scam Message Detected';
      summary = 'This message shows clear warning signs of a scam trying to steal your account or money.';
      recommendedAction =
          '1. Never share any OTP or password with anyone.\n2. Do not click on any link in this message.\n3. Contact your bank or sender directly using their official number.';
    } else if (level == ThreatRiskLevel.medium) {
      title = 'Potentially Suspicious Message';
      summary = 'This message contains some unusual requests. Exercise caution before responding.';
      recommendedAction =
          '1. Check who sent this message before taking action.\n2. Do not make any payments or click unexpected links.\n3. Ask someone you trust if you feel unsure.';
    } else {
      title = 'Message Appears Normal';
      summary = 'No common fraud patterns, suspicious links, or OTP requests were found.';
      recommendedAction = 'You can read and reply safely as usual.';
    }

    return ThreatAnalysisResult(
      id: _uuid.v4(),
      eventId: event.id,
      eventType: MonitoringEventType.sms,
      riskScore: score,
      riskLevel: level,
      title: title,
      summary: summary,
      indicators: indicators,
      recommendedAction: recommendedAction,
      timestamp: DateTime.now(),
      metadata: event.metadata,
    );
  }

  ThreatAnalysisResult _analyzeUrl(MonitoringEvent event) {
    final urlStr = _extractContent(event).toLowerCase();
    int score = 0;
    final List<String> indicators = [];

    // Safe trusted domains check
    final isKnownSafe = RegExp(r'^(https:\/\/)?(www\.)?(google\.com|youtube\.com|wikipedia\.org|github\.com|flutter\.dev|microsoft\.com)(\/|$|\?)').hasMatch(urlStr);

    if (isKnownSafe) {
      score = 8;
      indicators.add('Well-known trusted website with valid encrypted connection.');
    } else {
      // Rule 1: IP address in place of domain
      if (RegExp(r'(http:\/\/|https:\/\/)?\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(urlStr)) {
        score += 40;
        indicators.add('Uses a numeric computer address instead of a real website name.');
      }

      // Rule 2: Insecure plain HTTP
      if (urlStr.startsWith('http://')) {
        score += 15;
        indicators.add('The connection is not secured (plain http instead of https).');
      }

      // Rule 3: High-risk TLDs
      if (RegExp(r'\.(xyz|top|buzz|club|tk|ml|ga|cf|gq|work|loan|bid|casa)(\/|$|\?)').hasMatch(urlStr)) {
        score += 30;
        indicators.add('Uses a website extension commonly associated with temporary fake sites.');
      }

      // Rule 4: Misleading brand/phishing keywords
      if (RegExp(r'(login|verify|kyc|bank|secure|account|update|otp|free|bonus|wallet|signin)').hasMatch(urlStr)) {
        score += 25;
        indicators.add('Contains sensitive keywords like "login", "bank", or "verify".');
      }

      // Rule 5: Deceptive typosquatting patterns
      if (RegExp(r'(paypa[l1]|amaz[o0]n|g[o0]{2}gle|sbi[-\s]?kyc|hdfc[-\s]?verify)').hasMatch(urlStr)) {
        score += 35;
        indicators.add('Looks like a fake copy of a popular brand or bank website name.');
      }

      // Rule 6: URL shorteners
      if (RegExp(r'(bit\.ly|tinyurl\.com|t\.co|is\.gd|rb\.gy)').hasMatch(urlStr)) {
        score += 20;
        indicators.add('Uses a shortened link that conceals where it really leads.');
      }

      // Rule 7: Excessive subdomains or parameters
      final segments = urlStr.split('.');
      if (segments.length > 4) {
        score += 15;
        indicators.add('Unusually complex website address designed to confuse visitors.');
      }

      if (indicators.isEmpty) {
        score = 15;
        indicators.add('Standard website structure with standard security indicators.');
      }
    }

    score = score.clamp(0, 100);
    final level = _classify(score);

    String title;
    String summary;
    String recommendedAction;

    if (level == ThreatRiskLevel.high) {
      title = 'Dangerous Link Detected';
      summary = 'This website looks like a fake page designed to steal your confidential information.';
      recommendedAction =
          '1. Do NOT open this link.\n2. Do NOT enter any username, password, or banking information.\n3. Delete or ignore the message containing this link.';
    } else if (level == ThreatRiskLevel.medium) {
      title = 'Potentially Suspicious Link';
      summary = 'This link has some unexpected characteristics. It may not lead where you expect.';
      recommendedAction =
          '1. Only proceed if you completely trust the sender.\n2. Check the spelling of the website carefully before typing anything.\n3. When in doubt, search for the official website manually.';
    } else {
      title = 'Link Appears Safe';
      summary = 'No deceptive patterns or phishing indicators were found in this web address.';
      recommendedAction = 'You can browse this link normally, but always check for secure padlock in your browser.';
    }

    return ThreatAnalysisResult(
      id: _uuid.v4(),
      eventId: event.id,
      eventType: MonitoringEventType.url,
      riskScore: score,
      riskLevel: level,
      title: title,
      summary: summary,
      indicators: indicators,
      recommendedAction: recommendedAction,
      timestamp: DateTime.now(),
      metadata: event.metadata,
    );
  }

  ThreatAnalysisResult _analyzeApp(MonitoringEvent event) {
    final text = _extractContent(event).toLowerCase();
    int score = 0;
    final List<String> indicators = [];

    // Rule 1: Unknown source or sideloaded APK
    if (text.contains('unknown') || text.contains('.apk') || text.contains('sideload') || text.contains('download')) {
      score += 35;
      indicators.add('Installed from an unknown source outside the official Google Play Store.');
    }

    // Rule 2: Sensitive permissions requested
    if (text.contains('sms') || text.contains('contact') || text.contains('accessibility') || text.contains('overlay') || text.contains('permission')) {
      score += 30;
      indicators.add('Requests access to your private SMS messages or sensitive phone controls.');
    }

    // Rule 3: Suspicious loan, lottery or speed booster names
    if (RegExp(r'(loan|cash|fast|boost|cleaner|hack|free)').hasMatch(text)) {
      score += 20;
      indicators.add('App name contains promotional claims commonly found in adware or fake loan apps.');
    }

    if (indicators.isEmpty) {
      score = 25;
      indicators.add('App installed through regular channels; standard permissions requested.');
    }

    score = score.clamp(0, 100);
    final level = _classify(score);

    String title;
    String summary;
    String recommendedAction;

    if (level == ThreatRiskLevel.high) {
      title = 'High Risk Application Alert';
      summary = 'This application was installed from an unverified source and asks for powerful permissions.';
      recommendedAction =
          '1. Consider uninstalling this application immediately.\n2. Do not grant it SMS, contacts, or accessibility permissions.\n3. Only install apps from the Google Play Store.';
    } else if (level == ThreatRiskLevel.medium) {
      title = 'Potentially Suspicious Application';
      summary = 'This newly installed app requires permissions you should carefully review.';
      recommendedAction =
          '1. Open Phone Settings > Apps and check what permissions this app uses.\n2. Revoke SMS or location permissions if the app does not need them.\n3. Remove the app if you did not intentionally install it.';
    } else {
      title = 'Application Appears Safe';
      summary = 'Verified installation source with no unusual permission requests detected.';
      recommendedAction = 'No immediate action required. Keep your apps updated.';
    }

    return ThreatAnalysisResult(
      id: _uuid.v4(),
      eventId: event.id,
      eventType: MonitoringEventType.app,
      riskScore: score,
      riskLevel: level,
      title: title,
      summary: summary,
      indicators: indicators,
      recommendedAction: recommendedAction,
      timestamp: DateTime.now(),
      metadata: event.metadata,
    );
  }

  ThreatAnalysisResult _analyzeEmail(MonitoringEvent event) {
    // Reuses SMS detection logic for message text with email context
    final smsResult = _analyzeSms(event);
    return ThreatAnalysisResult(
      id: smsResult.id,
      eventId: event.id,
      eventType: MonitoringEventType.email,
      riskScore: smsResult.riskScore,
      riskLevel: smsResult.riskLevel,
      title: smsResult.title.replaceAll('Message', 'Email'),
      summary: smsResult.summary.replaceAll('message', 'email'),
      indicators: smsResult.indicators.map((i) => i.replaceAll('message', 'email')).toList(),
      recommendedAction: smsResult.recommendedAction.replaceAll('message', 'email'),
      timestamp: smsResult.timestamp,
      metadata: event.metadata,
    );
  }

  ThreatAnalysisResult _analyzeDevice(MonitoringEvent event) {
    final text = _extractContent(event).toLowerCase();
    int score = 20;
    final List<String> indicators = [];

    if (text.contains('developer') || text.contains('usb debugging')) {
      score += 30;
      indicators.add('Developer options or USB debugging is enabled on this phone.');
    }
    if (text.contains('root') || text.contains('jailbreak')) {
      score += 45;
      indicators.add('System security modifications were detected.');
    }
    if (text.contains('lock') || text.contains('pin')) {
      score += 20;
      indicators.add('Screen lock security could be strengthened.');
    }

    if (indicators.isEmpty) {
      indicators.add('Standard system settings; core security protections active.');
    }

    score = score.clamp(0, 100);
    final level = _classify(score);

    return ThreatAnalysisResult(
      id: _uuid.v4(),
      eventId: event.id,
      eventType: MonitoringEventType.device,
      riskScore: score,
      riskLevel: level,
      title: level == ThreatRiskLevel.high
          ? 'Device Security Alert'
          : level == ThreatRiskLevel.medium
              ? 'Device Setting Review Suggested'
              : 'Device Protection Normal',
      summary: level == ThreatRiskLevel.low
          ? 'Your phone settings are safe and secure.'
          : 'Some phone settings lower your protection against malware.',
      indicators: indicators,
      recommendedAction: level == ThreatRiskLevel.low
          ? 'Keep your Android system updated.'
          : 'Review device settings to ensure developer options and unknown apps remain turned off.',
      timestamp: DateTime.now(),
      metadata: event.metadata,
    );
  }

  String _extractContent(MonitoringEvent event) {
    if (event.metadata != null) {
      if (event.metadata!['text'] != null) return event.metadata!['text'].toString();
      if (event.metadata!['url'] != null) return event.metadata!['url'].toString();
      if (event.metadata!['message'] != null) return event.metadata!['message'].toString();
      if (event.metadata!['appName'] != null) return event.metadata!['appName'].toString();
    }
    return event.source;
  }

  ThreatRiskLevel _classify(int score) {
    if (score >= 70) return ThreatRiskLevel.high;
    if (score >= 40) return ThreatRiskLevel.medium;
    return ThreatRiskLevel.low;
  }
}
