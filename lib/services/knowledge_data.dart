import 'package:flutter/material.dart';
import '../models/knowledge_entry.dart';
import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';

/// Curated, offline cybersecurity knowledge base entries for SecureSphere.
/// Written in simple, friendly, jargon-free English for all digital citizens.
class KnowledgeData {
  static const List<KnowledgeEntry> entries = [
    // 1. OTP Scam
    KnowledgeEntry(
      id: 'otp_scam',
      title: 'OTP & Secret Code Theft',
      category: KnowledgeCategory.paymentSafety,
      description:
          'Never share your OTP (One Time Password) with anyone. Bank staff and customer care never ask for your OTP.',
      riskLevel: ThreatRiskLevel.high,
      howScammersDoIt:
          'Scammers call or message you pretending to be bank staff, electricity officers, or delivery agents. They claim your account will be blocked or a package cannot be delivered unless you read out the 4 or 6-digit code sent to your phone.',
      warningSigns: [
        'Caller asks you to read or forward an SMS code.',
        'Urgent threats that your bank account, SIM card, or electricity will stop today.',
        'Someone says they sent you money by mistake and asks for a verification code.',
        'Voice call or message asking for a code while you are not making any transaction.',
      ],
      recommendedActions: [
        'Cut the phone call immediately.',
        'Never read, forward, or type your OTP anywhere.',
        'If you shared an OTP, open your bank app or call your bank emergency helpline right now to freeze your card or account.',
        'Report the fraudulent phone number on the national cybercrime portal (1930).',
      ],
      preventionTips: [
        'Remember: OTP is like your digital house key. Never give it to strangers.',
        'Read the full SMS text: it always says "Do NOT share this code with anyone".',
        'Official banks will never call and ask for your OTP or PIN.',
      ],
      keywords: ['otp', 'pin', 'code', 'sms', 'bank', 'verification', 'block', 'kyc', 'password'],
      icon: Icons.pin_outlined,
      relatedEventTypes: [MonitoringEventType.sms, MonitoringEventType.email],
    ),

    // 2. UPI Payment Scams
    KnowledgeEntry(
      id: 'upi_scam',
      title: 'Suspicious UPI & QR Code Scams',
      category: KnowledgeCategory.paymentSafety,
      description:
          'Entering your UPI PIN always DEDUCTS money from your bank. You NEVER need to enter your PIN to receive money.',
      riskLevel: ThreatRiskLevel.high,
      howScammersDoIt:
          'A fraudster posing as an online buyer, landlord, or lottery sender sends you a QR code or a payment request on Google Pay, PhonePe, or Paytm. They claim: "Scan this QR code to receive Rs. 5,000". Once you scan it and enter your PIN, the money leaves your account instead.',
      warningSigns: [
        'Someone asks you to scan a QR code or enter your UPI PIN to "receive" funds.',
        'You receive a "Collect Request" notification from an unknown name.',
        'The person rushes you saying "The payment offer will expire in 5 minutes".',
        'Request to test a small transaction of 1 rupee first.',
      ],
      recommendedActions: [
        'Decline and reject any unexpected UPI collect requests.',
        'Never scan a QR code sent over WhatsApp or SMS to receive money.',
        'If money was stolen, call the National Cyber Helpline at 1930 immediately.',
        'Block the sender’s UPI ID in your payment app.',
      ],
      preventionTips: [
        'Golden Rule: You only enter UPI PIN to SEND money, never to RECEIVE money.',
        'Receiving money happens automatically into your account without pressing buttons.',
        'Never share screenshots of your payment history or account balances with strangers.',
      ],
      keywords: ['upi', 'qr', 'payment', 'phonepe', 'gpay', 'paytm', 'money', 'scam', 'collect', 'transfer'],
      icon: Icons.qr_code_scanner,
      relatedEventTypes: [MonitoringEventType.sms, MonitoringEventType.url],
    ),

    // 3. Phishing Links
    KnowledgeEntry(
      id: 'phishing_links',
      title: 'Dangerous & Fake Web Links',
      category: KnowledgeCategory.safeLinks,
      description:
          'Scammers create fake websites that look identical to genuine bank or shopping sites to steal your login and card details.',
      riskLevel: ThreatRiskLevel.high,
      howScammersDoIt:
          'You receive a link via SMS or WhatsApp with words like "Update KYC immediately" or "Claim your 10,000 reward". The link opens a webpage that looks just like your bank or mobile company, asking for your name, phone, card number, and password.',
      warningSigns: [
        'Web addresses ending in unusual names like .xyz, .top, .info, or random numbers (like 192.168.x.x).',
        'Links that use short URLs (bit.ly, tinyurl, t.co) to hide the real destination.',
        'Website does not show the secure lock symbol (https://) in the browser address bar.',
        'The message threatens suspension or promises free gifts if you don’t click right now.',
      ],
      recommendedActions: [
        'Do NOT tap or open the link.',
        'If you opened it, close your browser tab immediately without typing any information.',
        'If you entered your password, go to the official app or real website and change it at once.',
        'Delete the message so you or family members don’t accidentally tap it later.',
      ],
      preventionTips: [
        'Always type the official website address yourself in the browser.',
        'Check spelling carefully: scammers use fake names like "sbi-secure-update.xyz" instead of the real bank website.',
        'Banks never ask you to update KYC via an SMS link.',
      ],
      keywords: ['link', 'url', 'phishing', 'website', 'kyc', 'bit.ly', 'fake link', 'click', 'browser'],
      icon: Icons.link_off,
      relatedEventTypes: [MonitoringEventType.url, MonitoringEventType.sms, MonitoringEventType.email],
    ),

    // 4. Fake Customer Care
    KnowledgeEntry(
      id: 'fake_customer_care',
      title: 'Fake Customer Care & Bank Staff Calls',
      category: KnowledgeCategory.scamProtection,
      description:
          'Fraudsters post fake phone numbers on Google and search engines pretending to be customer support for banks, airlines, or shopping apps.',
      riskLevel: ThreatRiskLevel.high,
      howScammersDoIt:
          'When you search for "refund customer care number" online, you might find a fraudster’s phone number. When you call, they act polite and helpful, then ask you to download an app (like AnyDesk or TeamViewer) or enter your card details to process your refund.',
      warningSigns: [
        'The customer care executive answers from a personal mobile number (starting with +91 9xxx or +91 7xxx).',
        'They ask you to download screen-sharing or remote apps onto your phone.',
        'They ask for your ATM card number, expiry date, and 3-digit CVV.',
        'They demand a fee or asking you to make a Rs. 5 or Rs. 10 transaction to verify your account.',
      ],
      recommendedActions: [
        'Hang up the phone immediately.',
        'Never install any remote access or screen-sharing applications.',
        'If you installed an app on their advice, uninstall it right away and turn off your internet.',
        'Look up official customer care only inside the verified app you installed from Google Play Store.',
      ],
      preventionTips: [
        'Never search for customer service phone numbers on Google Search or social media.',
        'Only use help options directly inside your official banking or shopping app.',
        'Real customer support never needs remote screen access to your personal phone.',
      ],
      keywords: ['customer care', 'bank staff', 'call', 'fake call', 'refund', 'helpline', 'support', 'impersonation'],
      icon: Icons.support_agent,
      relatedEventTypes: [MonitoringEventType.sms, MonitoringEventType.app],
    ),

    // 5. Fake Apps & Malicious APKs
    KnowledgeEntry(
      id: 'fake_apps',
      title: 'Dangerous Apps & Fake Loan APKs',
      category: KnowledgeCategory.mobileSafety,
      description:
          'Downloading apps from websites, WhatsApp, or unknown links can infect your phone with malware that steals photos, contacts, and SMS messages.',
      riskLevel: ThreatRiskLevel.high,
      howScammersDoIt:
          'Scammers advertise instant loans, free movie apps, or WhatsApp bonus features via social media. They send you an APK installation file (e.g. FreeLoan.apk). Once installed, the app quietly reads your private messages and sends them to hackers.',
      warningSigns: [
        'File name ends with ".apk" sent to you over chat or downloaded from an internet link.',
        'App asks for permissions it doesn’t need, such as SMS access, Accessibility, or Contacts for a calculator or flashlight.',
        'The app is not available on Google Play Store.',
        'Your phone pops up a warning: "Install unknown apps blocked for your security".',
      ],
      recommendedActions: [
        'Cancel the installation immediately and delete the downloaded file.',
        'If already installed, go to Phone Settings > Apps > find the suspicious app and tap Uninstall.',
        'Revoke "Install Unknown Apps" permission in your phone security settings.',
        'Run a security scan to make sure no background spyware remains.',
      ],
      preventionTips: [
        'Only download apps from the official Google Play Store.',
        'Never bypass Android security warnings to install files received on WhatsApp or Telegram.',
        'Review app permissions: ask yourself why a loan app needs access to your camera and gallery.',
      ],
      keywords: ['app', 'apk', 'malware', 'virus', 'loan', 'install', 'unknown', 'download', 'permissions'],
      icon: Icons.android,
      relatedEventTypes: [MonitoringEventType.app, MonitoringEventType.device],
    ),

    // 6. Suspicious SMS & WhatsApp Messages
    KnowledgeEntry(
      id: 'suspicious_messages',
      title: 'Scam Messages on SMS & WhatsApp',
      category: KnowledgeCategory.emailMessages,
      description:
          'Watch out for messages promising part-time work, free gifts, electricity bill cut-offs, or lucky draw cash prizes.',
      riskLevel: ThreatRiskLevel.medium,
      howScammersDoIt:
          'Criminals send thousands of messages claiming: "Work 10 minutes a day and earn Rs. 3,000 liking YouTube videos" or "Your electricity power will be cut tonight at 9:30 PM due to unpaid bill". When you reply, they trap you into paying deposits or revealing confidential data.',
      warningSigns: [
        'Sent from an unknown international or standard mobile number rather than an official sender ID.',
        'Contains urgent warnings about electricity disconnection, parcel hold, or SIM block.',
        'Promises unbelievable easy money or lottery winnings for a contest you never entered.',
        'Contains spelling errors, grammatical mistakes, or weird formatting.',
      ],
      recommendedActions: [
        'Do not reply, call back, or click any link in the message.',
        'Report and block the sender inside WhatsApp or your messaging app.',
        'If it mentions a bill, verify it on your official utility bill receipt or provider app.',
        'Warn family members who might receive the same message.',
      ],
      preventionTips: [
        'If an offer sounds too good to be true, it is almost certainly a scam.',
        'Government departments and utility companies do not send bill disconnection notices from personal mobile numbers.',
        'Keep SecureSphere background monitoring enabled to check incoming messages safely.',
      ],
      keywords: ['sms', 'whatsapp', 'message', 'job', 'lottery', 'electricity', 'prize', 'earn', 'text'],
      icon: Icons.chat,
      relatedEventTypes: [MonitoringEventType.sms],
    ),

    // 7. Password Security
    KnowledgeEntry(
      id: 'password_security',
      title: 'Strong Passwords & Account Protection',
      category: KnowledgeCategory.passwordSafety,
      description:
          'A strong password stops hackers from guessing your login details and breaking into your social media, email, or bank accounts.',
      riskLevel: ThreatRiskLevel.medium,
      howScammersDoIt:
          'Hackers use automated tools to guess common passwords like "123456", your name, or your birthday. If you use the same password across multiple websites, a leak on one site gives hackers access to all your other accounts.',
      warningSigns: [
        'You receive an email or SMS stating: "Unrecognized login attempt detected".',
        'You are logged out of your account unexpectedly.',
        'Friends tell you that you are sending strange messages on Facebook, Instagram, or WhatsApp.',
      ],
      recommendedActions: [
        'Change your password immediately using a strong combination of letters, numbers, and symbols.',
        'Enable 2-Step Verification (Two-Factor Authentication) on your Google and WhatsApp accounts.',
        'Log out of all other active sessions from your account security settings.',
      ],
      preventionTips: [
        'Never use obvious passwords such as your name, 123456, or date of birth.',
        'Use a different password for your primary email and banking accounts.',
        'Never write passwords on paper taped to your phone or share them over chat.',
      ],
      keywords: ['password', 'login', 'account', 'security', 'hack', 'protection', 'lock', 'pin'],
      icon: Icons.password,
      relatedEventTypes: [MonitoringEventType.email, MonitoringEventType.device],
    ),

    // 8. Identity & Document Theft
    KnowledgeEntry(
      id: 'identity_theft',
      title: 'Protecting Aadhaar, PAN & Identity',
      category: KnowledgeCategory.privacy,
      description:
          'Never send photos of your Aadhaar card, PAN card, or bank passbook to unknown people on WhatsApp or social media.',
      riskLevel: ThreatRiskLevel.high,
      howScammersDoIt:
          'Fraudsters create fake job postings or rental house ads and ask you to send your Aadhaar, PAN, and selfie photo "for background verification". They then use your documents to take fraudulent loans or buy SIM cards in your name.',
      warningSigns: [
        'Unverified person on Facebook or WhatsApp demands identity proof before meeting you.',
        'Requests for both front and back photos of your PAN and Aadhaar for casual queries.',
        'Unsolicited calls congratulating you on loan approvals you never requested.',
      ],
      recommendedActions: [
        'Refuse to send identity documents to unverified individuals.',
        'If sharing Aadhaar is necessary, use Masked Aadhaar (where only the last 4 digits are visible).',
        'Lock your Aadhaar biometrics using the official mAadhaar application.',
        'Check your credit report regularly to ensure no unauthorized loans were opened in your name.',
      ],
      preventionTips: [
        'Write the purpose across the photocopy (e.g. "Shared only for SIM verification on date") before handing it over.',
        'Never upload identity documents to unsecured websites or public computers.',
        'Keep physical cards securely in your wallet, not exposed.',
      ],
      keywords: ['aadhaar', 'pan', 'identity', 'id', 'documents', 'privacy', 'card', 'fraud'],
      icon: Icons.badge_outlined,
      relatedEventTypes: [MonitoringEventType.sms, MonitoringEventType.email],
    ),

    // 9. Device & Wi-Fi Safety
    KnowledgeEntry(
      id: 'device_wifi_safety',
      title: 'Public Wi-Fi & Phone Security Settings',
      category: KnowledgeCategory.mobileSafety,
      description:
          'Free public Wi-Fi networks in railway stations, cafes, and parks are open and unencrypted. Avoid making bank payments on them.',
      riskLevel: ThreatRiskLevel.medium,
      howScammersDoIt:
          'Hackers set up fake Wi-Fi hotspots named "Free_Station_WiFi". When you connect, they can monitor unencrypted internet traffic and attempt to redirect you to fraudulent login pages.',
      warningSigns: [
        'Wi-Fi network asks for no password and connects immediately.',
        'Multiple Wi-Fi networks with similar names appear (e.g. "Cafe_Free_Wifi" vs "Cafe_Wifi_Free").',
        'Your phone warns that Developer Mode or USB Debugging is turned on without your knowledge.',
      ],
      recommendedActions: [
        'Turn off Wi-Fi and use your mobile cellular data when making payments or opening bank apps.',
        'Turn off "Auto-connect to open Wi-Fi networks" in phone settings.',
        'Keep your phone software and security updates up to date.',
        'Turn off Developer Options and USB Debugging when not in use.',
      ],
      preventionTips: [
        'Use mobile data (4G/5G) for banking; it is much safer than public public hotspots.',
        'Set a screen lock (fingerprint, pattern, or PIN) so nobody can access your phone if lost.',
        'Never leave your phone unattended with strangers.',
      ],
      keywords: ['wifi', 'device', 'public wifi', 'bluetooth', 'developer options', 'usb', 'settings', 'phone'],
      icon: Icons.wifi_lock,
      relatedEventTypes: [MonitoringEventType.device],
    ),

    // 10. Social Engineering & Urgency
    KnowledgeEntry(
      id: 'social_engineering',
      title: 'False Urgency & Emotional Pressure',
      category: KnowledgeCategory.commonThreats,
      description:
          'Scammers create panic or extreme excitement to make you act quickly before you have time to think or ask family members.',
      riskLevel: ThreatRiskLevel.high,
      howScammersDoIt:
          'A caller claims to be a police officer, customs official, or hospital doctor. They say your child or relative has been arrested or met with an accident, and you must send money immediately to save them or pay bail.',
      warningSigns: [
        'Extreme urgency: "Send money within 10 minutes or it will be too late!".',
        'They tell you: "Do NOT tell anyone, keep this confidential".',
        'Demanding immediate transfer via UPI or gift cards instead of following legal procedure.',
        'Caller sounds stressed, aggressive, or authoritatively demanding.',
      ],
      recommendedActions: [
        'Take a deep breath and PAUSE. Do not transfer any money immediately.',
        'Call your family member or child directly on their known phone number to verify their safety.',
        'Ask a family member or trusted neighbor to listen to the call.',
        'Real police and government officers never demand money transfers over the phone.',
      ],
      preventionTips: [
        'Whenever someone demands money urgently, STOP and talk to someone you trust.',
        'Scammers rely on your fear and hurry. Slowing down always protects you.',
        'Save official local police station numbers in your contacts.',
      ],
      keywords: ['urgency', 'police', 'arrest', 'scam', 'pressure', 'accident', 'fear', 'threat', 'emergency'],
      icon: Icons.warning_amber,
      relatedEventTypes: [MonitoringEventType.sms],
    ),

    // 11. Suspicious Emails & Impersonation
    KnowledgeEntry(
      id: 'suspicious_emails',
      title: 'Suspicious Emails & Fake Invoices',
      category: KnowledgeCategory.emailMessages,
      description:
          'Scam emails pretend to be from tax departments, banks, or online stores sending unexpected bills, invoices, or prizes.',
      riskLevel: ThreatRiskLevel.medium,
      howScammersDoIt:
          'You receive an email claiming: "Invoice for your purchase of Rs. 45,000 attached. If you did not make this order, call this number immediately". When you open the attachment or call, they attempt to steal your payment details.',
      warningSigns: [
        'Sender email address looks strange (e.g. support@bank-security192.com instead of the real bank domain).',
        'Attachments ending with .zip, .exe, or .apk.',
        'Generic greetings like "Dear Customer" instead of your real name.',
        'Threats of legal action or account termination.',
      ],
      recommendedActions: [
        'Do not download or open any attachments.',
        'Do not click any buttons or links inside the email.',
        'Mark the email as Spam / Phishing in your email app.',
        'If you are concerned about your account, check directly inside your official banking or shopping app.',
      ],
      preventionTips: [
        'Always inspect the sender’s full email address, not just the display name.',
        'Never enable macros or permissions if a downloaded document asks for them.',
        'Official companies address you by your registered account name.',
      ],
      keywords: ['email', 'invoice', 'attachment', 'bill', 'spam', 'phishing', 'tax', 'order'],
      icon: Icons.mark_email_unread_outlined,
      relatedEventTypes: [MonitoringEventType.email],
    ),

    // 12. Privacy & Personal Information
    KnowledgeEntry(
      id: 'privacy_protection',
      title: 'Privacy & Social Media Sharing',
      category: KnowledgeCategory.privacy,
      description:
          'Sharing your location, phone number, and daily routine publicly on social media makes it easy for scammers to target you.',
      riskLevel: ThreatRiskLevel.low,
      howScammersDoIt:
          'Fraudsters look at public profiles on Facebook or Instagram to find your phone number, friends, family members, and where you travel. They use these details to call you and pretend to be your friend or acquaintance.',
      warningSigns: [
        'Friend requests from people you are already friends with (cloned profiles).',
        'Strangers messaging you asking personal questions about your family or job.',
        'Quizzes or games on social media asking for your mother’s maiden name or birthplace.',
      ],
      recommendedActions: [
        'Change your social media profile privacy settings to "Friends Only".',
        'Hide your phone number and email address from public view.',
        'Never accept friend requests from duplicate or unverified accounts.',
      ],
      preventionTips: [
        'Avoid posting photos of travel tickets, boarding passes, or identity documents.',
        'Turn off location sharing for apps that do not require it.',
        'Regularly review which third-party apps have access to your accounts.',
      ],
      keywords: ['privacy', 'social media', 'facebook', 'instagram', 'profile', 'personal info', 'data'],
      icon: Icons.shield,
      relatedEventTypes: [MonitoringEventType.device],
    ),
  ];
}
