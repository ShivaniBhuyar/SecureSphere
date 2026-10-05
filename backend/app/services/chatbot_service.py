import re
import uuid
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session

from app.schemas.chatbot import ChatRequest, ChatResponse, IncidentGuidance
from app.services.knowledge_service import KnowledgeService, SEED_ENTRIES
from app.services.threat_analyzer import ThreatAnalyzerService
from app.services.alert_service import AlertService

class ChatbotService:
    # In-memory conversation session store (capped per session)
    _conversations: Dict[str, List[Dict[str, str]]] = {}
    MAX_HISTORY = 12

    # Malicious / Offensive keyword detector for Safety Guardrails
    OFFENSIVE_PATTERNS = [
        r'\b(how to hack|crack password|bypass otp|ddos attack|steal credentials|create ransomware|keylogger)\b',
        r'\b(hack whatsapp|hack instagram|hack facebook|hack wifi|sniff passwords|spoof caller id)\b',
        r'\b(exploit payload|sql injection payload|reverse shell|trojan source code)\b',
    ]

    @classmethod
    def _is_unsafe_request(cls, text: str) -> bool:
        lower = text.lower()
        for pattern in cls.OFFENSIVE_PATTERNS:
            if re.search(pattern, lower):
                return True
        return False

    @classmethod
    def _get_or_create_conversation_id(cls, conversation_id: Optional[str]) -> str:
        if conversation_id and conversation_id.strip():
            return conversation_id.strip()
        return f"conv_{uuid.uuid4().hex[:12]}"

    @classmethod
    def _record_message(cls, conv_id: str, role: str, content: str):
        if conv_id not in cls._conversations:
            cls._conversations[conv_id] = []
        cls._conversations[conv_id].append({"role": role, "content": content})
        if len(cls._conversations[conv_id]) > cls.MAX_HISTORY:
            cls._conversations[conv_id] = cls._conversations[conv_id][-cls.MAX_HISTORY:]

    @classmethod
    def _get_history(cls, conv_id: str) -> List[Dict[str, str]]:
        return cls._conversations.get(conv_id, [])

    @classmethod
    async def process_message(cls, db: Session, req: ChatRequest) -> ChatResponse:
        conv_id = cls._get_or_create_conversation_id(req.conversationId)
        user_message = req.message.strip()
        lower_msg = user_message.lower()
        now_iso = datetime.now(timezone.utc).isoformat()

        # Record user message in session
        cls._record_message(conv_id, "user", user_message)
        history = cls._get_history(conv_id)

        # -------------------------------------------------------------
        # 1. SAFETY & ETHICAL GUARDRAIL ENFORCEMENT (Step 8)
        # -------------------------------------------------------------
        if cls._is_unsafe_request(user_message):
            response_text = (
                "🛡️ **Security & Safety Notice**\n\n"
                "I cannot provide instructions, tools, or techniques for unauthorized access, hacking, credential harvesting, or compromising devices.\n\n"
                "SecureSphere is dedicated exclusively to **defensive cybersecurity, fraud prevention, and device safety**. "
                "I can happily help you **protect** your accounts, secure your Wi-Fi, spot scams, or recover safely from a suspected cyber incident."
            )
            suggestions = [
                "How to protect my Wi-Fi network?",
                "How to set up strong 2-factor authentication?",
                "What to do if someone stole my password?",
                "How to spot phishing emails?"
            ]
            cls._record_message(conv_id, "assistant", response_text)
            return ChatResponse(
                message=response_text,
                conversationId=conv_id,
                suggestions=suggestions,
                relatedKnowledgeEntries=[],
                relatedAlerts=[],
                timestamp=now_iso,
            )

        # -------------------------------------------------------------
        # 2. CONTEXTUAL RESOLUTION: THREAT CONTEXT & ALERT CONTEXT (Steps 5 & 6)
        # -------------------------------------------------------------
        related_knowledge: List[Dict[str, Any]] = []
        related_alerts: List[Dict[str, Any]] = []
        incident_guidance: Optional[IncidentGuidance] = None
        threat_context: Optional[Dict[str, Any]] = None

        # Check client context payload if passed
        client_context = req.context or {}
        alert_ctx = client_context.get("alert")
        threat_ctx = client_context.get("threat")

        # -------------------------------------------------------------
        # 3. DIRECT ALERT QUERIES (Module 5 Integration)
        # -------------------------------------------------------------
        is_alert_query = (
            alert_ctx is not None or
            re.search(r'\b(alert|notification|warning|why did i get this|is my phone safe|device safe|threat level)\b', lower_msg)
        )

        if alert_ctx:
            # User specifically asking about an active alert
            alert_title = alert_ctx.get("title", "Security Alert")
            alert_level = alert_ctx.get("riskLevel", "high").upper()
            alert_reason = alert_ctx.get("reason", "Suspicious activity detected.")

            response_text = (
                f"🚨 **Alert Analysis: {alert_title}**\n\n"
                f"**Severity**: {alert_level}\n"
                f"**Reason**: {alert_reason}\n\n"
                f"**What this means:**\n"
                f"SecureSphere's real-time monitoring flagged this event because it exhibits behavioral patterns consistent with cyber threats.\n\n"
                f"**Recommended Steps:**\n"
                f"1. Do not interact with or approve the flagged action.\n"
                f"2. Inspect the alert details and verify the source.\n"
                f"3. If this was a message or link, block the sender immediately.\n"
                f"4. Keep SecureSphere background shield active."
            )
            related_alerts.append(alert_ctx)
            suggestions = [
                "What should I do right now?",
                "Is my personal data compromised?",
                "How to prevent this in the future?",
                "Check my current security status"
            ]
            cls._record_message(conv_id, "assistant", response_text)
            return ChatResponse(
                message=response_text,
                conversationId=conv_id,
                suggestions=suggestions,
                relatedKnowledgeEntries=[],
                relatedAlerts=related_alerts,
                timestamp=now_iso,
            )

        if re.search(r'\b(show my alerts|recent alerts|check alerts|my notifications|unread alerts)\b', lower_msg):
            recent_alerts = AlertService.get_alerts(db, limit=3)
            if recent_alerts:
                alert_summaries = []
                for a in recent_alerts:
                    alert_summaries.append(f"• **[{a.risk_level.upper()}]** {a.title} ({a.threat_type})")
                    related_alerts.append({
                        "id": a.id,
                        "title": a.title,
                        "riskLevel": a.risk_level,
                        "threatType": a.threat_type,
                        "reason": a.reason,
                        "isRead": a.is_read
                    })
                response_text = (
                    f"🛡️ You have **{len(recent_alerts)} recent security alert(s)** recorded:\n\n"
                    + "\n".join(alert_summaries) + "\n\n"
                    "Would you like me to explain any specific alert or guide you through remediation steps?"
                )
            else:
                response_text = (
                    "✅ **Good news!** You currently have **0 unread security alerts**.\n\n"
                    "Your device monitoring is active and no critical threats are pending review."
                )
            suggestions = [
                "How does background monitoring work?",
                "Check a suspicious message",
                "What are the top safety rules?",
                "How to protect my bank account?"
            ]
            cls._record_message(conv_id, "assistant", response_text)
            return ChatResponse(
                message=response_text,
                conversationId=conv_id,
                suggestions=suggestions,
                relatedKnowledgeEntries=[],
                relatedAlerts=related_alerts,
                timestamp=now_iso,
            )

        # -------------------------------------------------------------
        # 4. SUSPICIOUS CONTENT & THREAT ANALYSIS (Module 3 Integration)
        # -------------------------------------------------------------
        is_url_in_msg = bool(re.search(r'https?://[^\s]+', user_message))
        is_message_check = (
            re.search(r'(is this (a )?scam|check this|analyze this|suspicious message|received this message|received an sms|look at this link)', lower_msg)
            or (len(user_message.split()) > 6 and any(k in lower_msg for k in ['urgent', 'blocked', 'account', 'dear customer', 'apk', 'lottery', 'winner', 'electricity']))
        )

        if is_url_in_msg or (is_message_check and len(user_message) > 15):
            event_type = "url" if is_url_in_msg else "sms"
            analysis = await ThreatAnalyzerService.analyze(db, event_type=event_type, content=user_message)
            threat_context = analysis
            risk_level = analysis.get("riskLevel", "low").upper()
            score = analysis.get("riskScore", 0)
            summary = analysis.get("summary", "")
            indicators = analysis.get("indicators", [])

            if score >= 40:
                threat_title = "Suspicious Digital Threat Detected"
                response_text = (
                    f"⚠️ **Threat Assessment: {risk_level} RISK (Score: {score}/100)**\n\n"
                    f"{summary}\n\n"
                    f"**Key Warning Indicators:**\n"
                    + "\n".join([f"• {ind}" for ind in indicators[:3]]) + "\n\n"
                    f"**🛡️ Immediate Safety Actions:**\n"
                    f"1. **Do NOT** tap any links or dial numbers mentioned in the message.\n"
                    f"2. **Do NOT** share any OTP, passwords, or personal details.\n"
                    f"3. Block the sender number or domain immediately.\n"
                    f"4. Delete or report the message as spam."
                )
                incident_guidance = IncidentGuidance(
                    threatIdentified=f"{risk_level} Risk {event_type.upper()} Threat",
                    severity=risk_level,
                    immediateActions=[
                        "Do not click the link or reply to the sender.",
                        "Never share OTPs, PINs, or bank card details.",
                        "Block and report the sender contact.",
                        "If you already clicked or shared details, contact your bank immediately."
                    ],
                    actionsToAvoid=[
                        "Do not forward the message to friends or family.",
                        "Do not download any attached APK files or files.",
                        "Do not call back unknown numbers claiming to be customer care."
                    ],
                    emergencyHelplines=[
                        "National Cybercrime Helpline: 1930",
                        "Official Portal: cybercrime.gov.in",
                        "Your Bank's 24/7 Emergency Card Freeze Hotline"
                    ]
                )
            else:
                response_text = (
                    f"✅ **Threat Assessment: LOW RISK (Score: {score}/100)**\n\n"
                    f"{summary}\n\n"
                    "No immediate high-risk patterns were detected. However, always verify unknown senders and never enter your passwords or banking PINs on unverified sites."
                )

            # Match related knowledge entry
            matching_kb = cls._find_matching_knowledge(lower_msg)
            if matching_kb:
                related_knowledge.append(matching_kb)

            suggestions = [
                "What if I already clicked the link?",
                "Someone asked for my OTP",
                "How to report cyber fraud?",
                "How to protect my bank account?"
            ]
            cls._record_message(conv_id, "assistant", response_text)
            return ChatResponse(
                message=response_text,
                conversationId=conv_id,
                suggestions=suggestions,
                relatedKnowledgeEntries=related_knowledge,
                relatedAlerts=[],
                incidentGuidance=incident_guidance,
                threatContext=threat_context,
                timestamp=now_iso,
            )

        # -------------------------------------------------------------
        # 5. INCIDENT GUIDANCE & KNOWLEDGE BASE INTEGRATION (Module 4)
        # -------------------------------------------------------------
        kb_entry = cls._find_matching_knowledge(lower_msg)
        if kb_entry:
            related_knowledge.append(kb_entry)

        # Topic 1: OTP & Secret Code Theft
        if any(w in lower_msg for w in ['otp', 'one-time password', 'verification code', 'secret code', 'read out code', 'forward code']):
            response_text = (
                "🔐 **CRITICAL OTP SAFETY RULE**\n\n"
                "**Never share your OTP (One Time Password) with anyone under any circumstances!**\n\n"
                "• **Bank employees, police, and customer support will NEVER ask for your OTP.**\n"
                "• Sharing an OTP gives a fraudster instant access to withdraw money or hijack your account.\n\n"
                "**What to do right now:**\n"
                "1. Disconnect or ignore the call/message immediately.\n"
                "2. If you already shared an OTP, open your bank app or call your bank emergency helpline **immediately** to freeze your account/cards.\n"
                "3. Dial **1930** to report financial cyber fraud."
            )
            incident_guidance = IncidentGuidance(
                threatIdentified="OTP / Secret Verification Code Theft",
                severity="CRITICAL",
                immediateActions=[
                    "Never read, forward, or type your OTP anywhere for a caller.",
                    "If already shared, freeze your bank account/cards immediately.",
                    "Call Cyber Crime Helpline at 1930."
                ],
                actionsToAvoid=[
                    "Never share OTP even if the caller claims to be a bank manager.",
                    "Never trust threats that electricity, SIM, or bank will be blocked today."
                ],
                emergencyHelplines=["1930 (National Cybercrime Reporting)", "Bank 24/7 Helpline"]
            )
            suggestions = [
                "What if I already shared my OTP?",
                "How to freeze my bank account?",
                "How do UPI scams work?",
                "What is phishing?"
            ]

        # Topic 2: UPI & QR Code Scams
        elif any(w in lower_msg for w in ['upi', 'qr code', 'scan qr', 'phonepe', 'gpay', 'paytm', 'collect request', 'receive money']):
            response_text = (
                "💳 **GOLDEN RULE OF UPI PAYMENTS**\n\n"
                "**You NEVER need to scan a QR code or enter your UPI PIN to RECEIVE money!**\n\n"
                "• Entering your UPI PIN will **always deduct money** from your account.\n"
                "• Receiving money happens automatically into your account without pressing any buttons.\n\n"
                "**What to do:**\n"
                "1. Decline and cancel any unexpected UPI 'Collect Requests'.\n"
                "2. Never scan QR codes sent via WhatsApp, OLX, or SMS.\n"
                "3. If money was deducted fraudulently, report immediately at **1930** and file a dispute in your UPI app."
            )
            incident_guidance = IncidentGuidance(
                threatIdentified="UPI / QR Code Payment Scam",
                severity="HIGH",
                immediateActions=[
                    "Decline all unverified collect requests on Google Pay / PhonePe / Paytm.",
                    "Never enter your 4 or 6-digit PIN to receive payments.",
                    "Report unauthorized transactions to your bank within 24 hours."
                ],
                actionsToAvoid=[
                    "Do not scan QR codes sent by online buyers or strangers.",
                    "Do not test transactions of 1 rupee requested by strangers."
                ],
                emergencyHelplines=["1930 (National Cybercrime)", "Your UPI App Support"]
            )
            suggestions = [
                "What should I do if someone asks for my OTP?",
                "How to identify fake customer care?",
                "What to do if money was stolen?",
                "Check a suspicious message"
            ]

        # Topic 3: Fake Customer Care & Remote Access
        elif any(w in lower_msg for w in ['customer care', 'bank official', 'anydesk', 'teamviewer', 'rustdesk', 'quicksupport', 'screen share', 'helpline']):
            response_text = (
                "📞 **FAKE CUSTOMER CARE & REMOTE ACCESS ALERT**\n\n"
                "**Scammers post fake customer care numbers on Google and ask you to install remote-screen apps.**\n\n"
                "• Never install apps like **AnyDesk, TeamViewer, RustDesk, or QuickSupport** when instructed by unknown callers.\n"
                "• These apps give fraudsters complete remote control of your phone and banking apps.\n\n"
                "**What to do:**\n"
                "1. Uninstall any remote access app installed at the caller's request immediately.\n"
                "2. Turn on Airplane mode or disconnect from Wi-Fi and Mobile Data.\n"
                "3. Check your bank balance from another verified device or via ATM.\n"
                "4. Always find customer care numbers only inside the official app or official website."
            )
            suggestions = [
                "How to check if an app is safe?",
                "What is phishing?",
                "How to protect my bank account?",
                "Check a suspicious link"
            ]

        # Topic 4: Phishing Links & Suspicious URLs
        elif any(w in lower_msg for w in ['phishing', 'fake link', 'suspicious link', 'bit.ly', 'url', 'fake website', 'login link', 'clicked a link']):
            response_text = (
                "🔗 **PHISHING LINK DEFENSE GUIDE**\n\n"
                "Phishing links mimic genuine banking, government, or shopping portals to harvest your passwords and card credentials.\n\n"
                "**How to identify fake links:**\n"
                "• Look at the exact domain: `sbi-kyc-update.xyz` is fake; `sbi.co.in` or `onlinesbi.sbi` is official.\n"
                "• Watch out for shortened links (`bit.ly`, `tinyurl`, `t.co`).\n"
                "• Check for secure HTTPS lock icon and correct spelling.\n\n"
                "**If you already clicked a suspicious link:**\n"
                "1. Close the browser tab immediately.\n"
                "2. If you typed passwords or banking PINs, change your passwords immediately from a safe browser.\n"
                "3. Run an antivirus scan or check for newly downloaded files in your Downloads folder."
            )
            suggestions = [
                "I clicked a suspicious link. What should I do?",
                "Someone asked for my OTP",
                "How to identify fake apps?",
                "Check a suspicious message"
            ]

        # Topic 5: Fake Apps & Malware APKs
        elif any(w in lower_msg for w in ['fake app', 'apk', 'install app', 'loan app', 'malware', 'virus', 'dangerous permission']):
            response_text = (
                "📱 **FAKE APPS & MALWARE APK PROTECTION**\n\n"
                "Downloading APKs outside the official Google Play Store or Apple App Store is extremely dangerous.\n\n"
                "• Fake loan apps, lotteries, and cloned apps often request SMS, Contact, and Accessibility permissions to intercept banking OTPs.\n\n"
                "**Defensive Steps:**\n"
                "1. Go to **Settings > Apps** and uninstall any unverified application.\n"
                "2. Ensure **Google Play Protect** is turned ON in the Play Store.\n"
                "3. Review app permissions: Never grant SMS or Accessibility permissions to calculators, flashlights, or unknown games."
            )
            suggestions = [
                "What permissions are dangerous?",
                "How to protect my Wi-Fi?",
                "What is social engineering?",
                "Check my current security status"
            ]

        # Topic 6: Social Engineering & Urgent Threats (Electricity, SIM, Police, Arrest)
        elif any(w in lower_msg for w in ['electricity', 'bill unpaid', 'sim blocked', 'police', 'cbi', 'digital arrest', 'urgent', 'threatened']):
            response_text = (
                "⚠️ **URGENT THREAT & FAKE ARREST SCAMS (Digital Arrest)**\n\n"
                "Scammers create artificial panic claiming:\n"
                "• *'Your electricity will be disconnected tonight at 9 PM'*.\n"
                "• *'Your SIM card will be deactivated in 24 hours'*.\n"
                "• *'Police / CBI warrants issued against your Aadhaar (Digital Arrest)'*.\n\n"
                "**Crucial Facts:**\n"
                "• Government agencies, police, and electricity boards **never** demand money transfers or threaten arrests over WhatsApp video calls.\n"
                "• There is no such legal procedure as a 'Digital Arrest' in law.\n\n"
                "**What to do:**\n"
                "1. Cut the call immediately. Do not panic.\n"
                "2. Never transfer money to 'verify your innocence'.\n"
                "3. Report the threatening number immediately to **1930** or at **cybercrime.gov.in**."
            )
            suggestions = [
                "What should I do if someone asks for my OTP?",
                "How do UPI scams work?",
                "How to report a scam number?",
                "How to protect my bank account?"
            ]

        # Topic 7: Password Security & 2FA
        elif any(w in lower_msg for w in ['password', '2fa', 'two-factor', 'mfa', 'strong password', 'secure password', 'account hacked', 'compromised']):
            response_text = (
                "🔑 **PASSWORD HYGIENE & ACCOUNT RECOVERY**\n\n"
                "**Best Practices:**\n"
                "• Use a unique, strong passphrase of at least 12+ characters for each critical account.\n"
                "• Enable **Two-Factor Authentication (2FA)** using an Authenticator app (Google Authenticator, Microsoft Authenticator) instead of plain SMS.\n"
                "• Never reuse your primary email or banking password across entertainment or shopping websites.\n\n"
                "**If you suspect your account was compromised:**\n"
                "1. Change the password immediately using 'Forgot Password' -> 'Log out of all devices'.\n"
                "2. Check recovery email and phone number to verify they haven't been altered.\n"
                "3. Review active sessions and revoke unknown device logins."
            )
            suggestions = [
                "What is phishing?",
                "How to protect my Wi-Fi network?",
                "What should I do if someone asks for my OTP?",
                "Check a suspicious link"
            ]

        # Topic 8: Public Wi-Fi & Device Security
        elif any(w in lower_msg for w in ['wifi', 'wi-fi', 'public wifi', 'hotspot', 'device safety', 'bluetooth']):
            response_text = (
                "📶 **PUBLIC WI-FI & DEVICE SAFETY**\n\n"
                "Open public Wi-Fi networks (airports, cafes, stations) are unencrypted and vulnerable to 'Man-in-the-Middle' packet sniffing.\n\n"
                "**Safety Checklist:**\n"
                "1. Avoid conducting banking transactions or entering credit card details on public Wi-Fi.\n"
                "2. Turn off auto-connect to open Wi-Fi networks in your phone settings.\n"
                "3. Keep Bluetooth and Hotspot disabled when not actively in use in crowded areas.\n"
                "4. Keep your phone OS and SecureSphere updated with the latest security patches."
            )
            suggestions = [
                "How to spot phishing links?",
                "What permissions are dangerous?",
                "How to set up strong 2FA?",
                "Check a suspicious message"
            ]

        # Topic 9: Follow-up handling ("What if I already clicked it?", "What if I already paid?", etc.)
        elif any(w in lower_msg for w in ['already clicked', 'already shared', 'already sent money', 'already paid', 'i got scammed', 'money deducted']):
            response_text = (
                "🚨 **EMERGENCY INCIDENT RECOVERY STEPS**\n\n"
                "If you have already fallen victim to a scam or shared sensitive credentials, act quickly to contain the damage:\n\n"
                "1. **Freeze Bank Account / Cards**: Call your bank's emergency 24/7 hotline immediately to block your debit/credit card and internet banking.\n"
                "2. **Report Financial Cyber Fraud (Golden Hour)**: Call **1930** (National Cybercrime Reporting Helpline in India) immediately. If reported quickly, the nodal officers can often freeze the recipient scammer's bank account before funds are withdrawn.\n"
                "3. **Change All Passwords**: From another safe device, change passwords on your email, banking, and social accounts.\n"
                "4. **File an Official Complaint**: Register the incident with evidence (screenshots, transaction IDs) at **cybercrime.gov.in**."
            )
            incident_guidance = IncidentGuidance(
                threatIdentified="Active Financial Cyber Incident",
                severity="CRITICAL",
                immediateActions=[
                    "Call bank helpline to freeze cards and account immediately.",
                    "Call National Cyber Helpline at 1930 right now.",
                    "Change email and banking passwords."
                ],
                actionsToAvoid=[
                    "Do not delete transaction SMS or call logs (they are evidence).",
                    "Do not pay additional 'refund fees' or 'clearance charges' demanded by fraudsters."
                ],
                emergencyHelplines=["1930 (Cyber Crime Helpline)", "cybercrime.gov.in", "Bank Emergency Number"]
            )
            suggestions = [
                "What details do I need for helpline 1930?",
                "How to protect my remaining accounts?",
                "How do UPI scams work?",
                "Check my current security status"
            ]

        # Topic 10: General Cybersecurity Assistant Introduction / Help
        else:
            response_text = (
                "👋 **I am SecureSphere AI Assistant**, your dedicated 24/7 cybersecurity companion.\n\n"
                "I can assist you with:\n"
                "• **Incident Guidance**: Step-by-step solutions if you suspect a scam, unauthorized debit, or hacked account.\n"
                "• **Threat & Message Verification**: Inspect suspicious SMS messages, emails, and links.\n"
                "• **Security Explanations**: Clarify security alerts, risk scores, and background monitoring signals.\n"
                "• **Fraud Prevention**: Best practices for OTP safety, UPI payments, QR codes, passwords, and public Wi-Fi.\n\n"
                "How can I help protect you today?"
            )
            suggestions = [
                "Someone is asking for my OTP",
                "Is this message a scam?",
                "How can I identify a fake UPI QR code?",
                "What should I do after clicking a suspicious link?"
            ]

        cls._record_message(conv_id, "assistant", response_text)

        return ChatResponse(
            message=response_text,
            conversationId=conv_id,
            suggestions=suggestions,
            relatedKnowledgeEntries=related_knowledge,
            relatedAlerts=related_alerts,
            incidentGuidance=incident_guidance,
            threatContext=threat_context,
            timestamp=now_iso,
        )

    @classmethod
    def _find_matching_knowledge(cls, text: str) -> Optional[Dict[str, Any]]:
        """Finds the highest scoring Module 4 knowledge entry for grounding."""
        text_lower = text.lower()
        words = set(re.findall(r'\b[a-z0-9_-]+\b', text_lower))
        best_entry = None
        best_score = 0

        for entry in SEED_ENTRIES:
            score = 0
            # Title token match
            title_words = set(re.findall(r'\b[a-z0-9_-]+\b', entry.get("title", "").lower()))
            overlap = words.intersection(title_words)
            score += len(overlap) * 3

            # Specific keyword matches
            for kw in entry.get("keywords", []):
                kw_lower = kw.lower()
                if kw_lower in text_lower:
                    if kw_lower in words:
                        score += 2
                    else:
                        score += 1
            if score > best_score:
                best_score = score
                best_entry = {
                    "id": entry["id"],
                    "title": entry["title"],
                    "category": entry["category"],
                    "description": entry["description"],
                    "riskLevel": entry["risk_level"],
                    "iconName": entry["icon_name"],
                }
        return best_entry if best_score > 0 else None

    @classmethod
    def get_default_suggestions(cls) -> List[str]:
        return [
            "What should I do if someone asks for my OTP?",
            "How can I identify a fake UPI QR code?",
            "What should I do after clicking a suspicious link?",
            "How do I know if an app is safe?",
            "What does my latest security alert mean?",
            "How can I protect my bank account?"
        ]
