class MockAIService {
  Future<String> getResponse(String question) async {
    // Simulate network/thinking delay
    await Future.delayed(const Duration(seconds: 2));

    final q = question.toLowerCase();

    if (q.contains('otp')) {
      return "Please don't share your OTP. 🔐\n\nYour OTP is private and should only be used by you.\n\nIf someone is asking you to tell them the OTP, stop and do not continue.";
    }

    if (q.contains('phishing')) {
      return "Phishing is a trick where someone pretends to be a trusted person or company to steal your information.\n\nFor example, a scammer may send a fake bank message asking you to click a link.";
    }

    if (q.contains('scam')) {
      return "I can help you check the warning signs.\n\nLook for urgent messages, unknown links, requests for OTPs, passwords or money.\n\nIf you are unsure, don't click anything yet.";
    }

    if (q.contains('safe')) {
      return "Here are three simple rules:\n\n1. Never share your OTP or PIN.\n2. Don't click unknown links.\n3. If something feels urgent or suspicious, stop and ask someone you trust.";
    }

    // Default response
    return "That's a good question. I can help with online scams, phishing, suspicious messages, links, OTP safety and general cybersecurity.\n\nTell me what happened and I'll guide you step by step.";
  }
}
