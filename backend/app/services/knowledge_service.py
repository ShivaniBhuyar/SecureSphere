import json
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.knowledge import KnowledgeEntryModel

# Initial verified seed entries for SecureSphere
SEED_ENTRIES = [
    {
        "id": "otp_scam",
        "title": "OTP & Secret Code Theft",
        "category": "Payment Safety",
        "description": "Never share your OTP (One Time Password) with anyone. Bank staff and customer care never ask for your OTP.",
        "risk_level": "high",
        "how_scammers_do_it": "Scammers call or message you pretending to be bank staff, electricity officers, or delivery agents. They claim your account will be blocked or a package cannot be delivered unless you read out the 4 or 6-digit code sent to your phone.",
        "warning_signs": [
            "Caller asks you to read or forward an SMS code.",
            "Urgent threats that your bank account, SIM card, or electricity will stop today.",
            "Someone says they sent you money by mistake and asks for a verification code.",
            "Voice call or message asking for a code while you are not making any transaction."
        ],
        "recommended_actions": [
            "Cut the phone call immediately.",
            "Never read, forward, or type your OTP anywhere.",
            "If you shared an OTP, open your bank app or call your bank emergency helpline right now to freeze your card or account.",
            "Report the fraudulent phone number on the national cybercrime portal (1930)."
        ],
        "prevention_tips": [
            "Remember: OTP is like your digital house key. Never give it to strangers.",
            "Read the full SMS text: it always says 'Do NOT share this code with anyone'.",
            "Official banks will never call and ask for your OTP or PIN."
        ],
        "keywords": ["otp", "pin", "code", "sms", "bank", "verification", "block", "kyc", "password"],
        "related_event_types": ["sms", "email"],
        "icon_name": "pin"
    },
    {
        "id": "upi_scam",
        "title": "Suspicious UPI & QR Code Scams",
        "category": "Payment Safety",
        "description": "Entering your UPI PIN always DEDUCTS money from your bank. You NEVER need to enter your PIN to receive money.",
        "risk_level": "high",
        "how_scammers_do_it": "A fraudster posing as an online buyer, landlord, or lottery sender sends you a QR code or a payment request on Google Pay, PhonePe, or Paytm. They claim: 'Scan this QR code to receive Rs. 5,000'. Once you scan it and enter your PIN, the money leaves your account instead.",
        "warning_signs": [
            "Someone asks you to scan a QR code or enter your UPI PIN to 'receive' funds.",
            "You receive a 'Collect Request' notification from an unknown name.",
            "The person rushes you saying 'The payment offer will expire in 5 minutes'.",
            "Request to test a small transaction of 1 rupee first."
        ],
        "recommended_actions": [
            "Decline and reject any unexpected UPI collect requests.",
            "Never scan a QR code sent over WhatsApp or SMS to receive money.",
            "If money was stolen, call the National Cyber Helpline at 1930 immediately.",
            "Block the sender's UPI ID in your payment app."
        ],
        "prevention_tips": [
            "Golden Rule: You only enter UPI PIN to SEND money, never to RECEIVE money.",
            "Receiving money happens automatically into your account without pressing buttons.",
            "Never share screenshots of your payment history or account balances with strangers."
        ],
        "keywords": ["upi", "qr", "payment", "phonepe", "gpay", "paytm", "money", "scam", "collect", "transfer"],
        "related_event_types": ["sms", "url"],
        "icon_name": "qr_code"
    },
    {
        "id": "phishing_links",
        "title": "Dangerous & Fake Web Links",
        "category": "Safe Links",
        "description": "Scammers create fake websites that look identical to genuine bank or shopping sites to steal your login and card details.",
        "risk_level": "high",
        "how_scammers_do_it": "You receive a link via SMS or WhatsApp with words like 'Update KYC immediately' or 'Claim your 10,000 reward'. The link opens a webpage that looks just like your bank or mobile company, asking for your name, phone, card number, and password.",
        "warning_signs": [
            "Web addresses ending in unusual names like .xyz, .top, .info, or random numbers (like 192.168.x.x).",
            "Links that use short URLs (bit.ly, tinyurl, t.co) to hide the real destination.",
            "Website does not show the secure lock symbol (https://) in the browser address bar.",
            "The message threatens suspension or promises free gifts if you don't click right now."
        ],
        "recommended_actions": [
            "Do NOT tap or open the link.",
            "If you opened it, close your browser tab immediately without typing any information.",
            "If you entered your password, go to the official app or real website and change it at once.",
            "Delete the message so you or family members don't accidentally tap it later."
        ],
        "prevention_tips": [
            "Always type the official website address yourself in the browser.",
            "Check spelling carefully: scammers use fake names like 'sbi-secure-update.xyz' instead of the real bank website.",
            "Banks never ask you to update KYC via an SMS link."
        ],
        "keywords": ["link", "url", "phishing", "website", "kyc", "bit.ly", "fake link", "click", "browser"],
        "related_event_types": ["url", "sms", "email"],
        "icon_name": "link_off"
    },
    {
        "id": "fake_customer_care",
        "title": "Fake Customer Care & Bank Staff Calls",
        "category": "Scam Protection",
        "description": "Fraudsters post fake phone numbers on Google and search engines pretending to be customer support for banks, airlines, or shopping apps.",
        "risk_level": "high",
        "how_scammers_do_it": "When you search for 'refund customer care number' online, you might find a fraudster's phone number. When you call, they act polite and helpful, then ask you to download an app (like AnyDesk or TeamViewer) or enter your card details to process your refund.",
        "warning_signs": [
            "The customer care executive answers from a personal mobile number (starting with +91 9xxx or +91 7xxx).",
            "They ask you to download screen-sharing or remote apps onto your phone.",
            "They ask for your ATM card number, expiry date, and 3-digit CVV.",
            "They demand a fee or asking you to make a Rs. 5 or Rs. 10 transaction to verify your account."
        ],
        "recommended_actions": [
            "Hang up the phone immediately.",
            "Never install any remote access or screen-sharing applications.",
            "If you installed an app on their advice, uninstall it right away and turn off your internet.",
            "Look up official customer care only inside the verified app you installed from Google Play Store."
        ],
        "prevention_tips": [
            "Never search for customer service phone numbers on Google Search or social media.",
            "Only use help options directly inside your official banking or shopping app.",
            "Real customer support never needs remote screen access to your personal phone."
        ],
        "keywords": ["customer care", "bank staff", "call", "fake call", "refund", "helpline", "support", "impersonation"],
        "related_event_types": ["sms", "app"],
        "icon_name": "support_agent"
    },
    {
        "id": "fake_apps",
        "title": "Dangerous Apps & Fake Loan APKs",
        "category": "Mobile Safety",
        "description": "Downloading apps from websites, WhatsApp, or unknown links can infect your phone with malware that steals photos, contacts, and SMS messages.",
        "risk_level": "high",
        "how_scammers_do_it": "Scammers advertise instant loans, free movie apps, or WhatsApp bonus features via social media. They send you an APK installation file (e.g. FreeLoan.apk). Once installed, the app quietly reads your private messages and sends them to hackers.",
        "warning_signs": [
            "File name ends with '.apk' sent to you over chat or downloaded from an internet link.",
            "App asks for permissions it doesn't need, such as SMS access, Accessibility, or Contacts for a calculator or flashlight.",
            "The app is not available on Google Play Store.",
            "Your phone pops up a warning: 'Install unknown apps blocked for your security'."
        ],
        "recommended_actions": [
            "Cancel the installation immediately and delete the downloaded file.",
            "If already installed, go to Phone Settings > Apps > find the suspicious app and tap Uninstall.",
            "Revoke 'Install Unknown Apps' permission in your phone security settings.",
            "Run a security scan to make sure no background spyware remains."
        ],
        "prevention_tips": [
            "Only download apps from the official Google Play Store.",
            "Never bypass Android security warnings to install files received on WhatsApp or Telegram.",
            "Review app permissions: ask yourself why a loan app needs access to your camera and gallery."
        ],
        "keywords": ["app", "apk", "malware", "virus", "loan", "install", "unknown", "download", "permissions"],
        "related_event_types": ["app", "device"],
        "icon_name": "android"
    },
    {
        "id": "suspicious_messages",
        "title": "Scam Messages on SMS & WhatsApp",
        "category": "Email & Messages",
        "description": "Watch out for messages promising part-time work, free gifts, electricity bill cut-offs, or lucky draw cash prizes.",
        "risk_level": "medium",
        "how_scammers_do_it": "Criminals send thousands of messages claiming: 'Work 10 minutes a day and earn Rs. 3,000 liking YouTube videos' or 'Your electricity power will be cut tonight at 9:30 PM due to unpaid bill'. When you reply, they trap you into paying deposits or revealing confidential data.",
        "warning_signs": [
            "Sent from an unknown international or standard mobile number rather than an official sender ID.",
            "Contains urgent warnings about electricity disconnection, parcel hold, or SIM block.",
            "Promises unbelievable easy money or lottery winnings for a contest you never entered.",
            "Contains spelling errors, grammatical mistakes, or weird formatting."
        ],
        "recommended_actions": [
            "Do not reply, call back, or click any link in the message.",
            "Report and block the sender inside WhatsApp or your messaging app.",
            "If it mentions a bill, verify it on your official utility bill receipt or provider app.",
            "Warn family members who might receive the same message."
        ],
        "prevention_tips": [
            "If an offer sounds too good to be true, it is almost certainly a scam.",
            "Government departments and utility companies do not send bill disconnection notices from personal mobile numbers.",
            "Keep SecureSphere background monitoring enabled to check incoming messages safely."
        ],
        "keywords": ["sms", "whatsapp", "message", "job", "lottery", "electricity", "prize", "earn", "text"],
        "related_event_types": ["sms"],
        "icon_name": "chat"
    },
    {
        "id": "password_security",
        "title": "Strong Passwords & Account Protection",
        "category": "Password Safety",
        "description": "A strong password stops hackers from guessing your login details and breaking into your social media, email, or bank accounts.",
        "risk_level": "medium",
        "how_scammers_do_it": "Hackers use automated tools to guess common passwords like '123456', your name, or your birthday. If you use the same password across multiple websites, a leak on one site gives hackers access to all your other accounts.",
        "warning_signs": [
            "You receive an email or SMS stating: 'Unrecognized login attempt detected'.",
            "You are logged out of your account unexpectedly.",
            "Friends tell you that you are sending strange messages on Facebook, Instagram, or WhatsApp."
        ],
        "recommended_actions": [
            "Change your password immediately using a strong combination of letters, numbers, and symbols.",
            "Enable 2-Step Verification (Two-Factor Authentication) on your Google and WhatsApp accounts.",
            "Log out of all other active sessions from your account security settings."
        ],
        "prevention_tips": [
            "Never use obvious passwords such as your name, 123456, or date of birth.",
            "Use a different password for your primary email and banking accounts.",
            "Never write passwords on paper taped to your phone or share them over chat."
        ],
        "keywords": ["password", "login", "account", "security", "hack", "protection", "lock", "pin"],
        "related_event_types": ["email", "device"],
        "icon_name": "password"
    },
    {
        "id": "identity_theft",
        "title": "Protecting Aadhaar, PAN & Identity",
        "category": "Privacy",
        "description": "Never send photos of your Aadhaar card, PAN card, or bank passbook to unknown people on WhatsApp or social media.",
        "risk_level": "high",
        "how_scammers_do_it": "Fraudsters create fake job postings or rental house ads and ask you to send your Aadhaar, PAN, and selfie photo 'for background verification'. They then use your documents to take fraudulent loans or buy SIM cards in your name.",
        "warning_signs": [
            "Unverified person on Facebook or WhatsApp demands identity proof before meeting you.",
            "Requests for both front and back photos of your PAN and Aadhaar for casual queries.",
            "Unsolicited calls congratulating you on loan approvals you never requested."
        ],
        "recommended_actions": [
            "Refuse to send identity documents to unverified individuals.",
            "If sharing Aadhaar is necessary, use Masked Aadhaar (where only the last 4 digits are visible).",
            "Lock your Aadhaar biometrics using the official mAadhaar application.",
            "Check your credit report regularly to ensure no unauthorized loans were opened in your name."
        ],
        "prevention_tips": [
            "Write the purpose across the photocopy before handing it over.",
            "Never upload identity documents to unsecured websites or public computers.",
            "Keep physical cards securely in your wallet, not exposed."
        ],
        "keywords": ["aadhaar", "pan", "identity", "id", "documents", "privacy", "card", "fraud"],
        "related_event_types": ["sms", "email"],
        "icon_name": "badge"
    },
    {
        "id": "device_wifi_safety",
        "title": "Public Wi-Fi & Phone Security Settings",
        "category": "Mobile Safety",
        "description": "Free public Wi-Fi networks in railway stations, cafes, and parks are open and unencrypted. Avoid making bank payments on them.",
        "risk_level": "medium",
        "how_scammers_do_it": "Hackers set up fake Wi-Fi hotspots named 'Free_Station_WiFi'. When you connect, they can monitor unencrypted internet traffic and attempt to redirect you to fraudulent login pages.",
        "warning_signs": [
            "Wi-Fi network asks for no password and connects immediately.",
            "Multiple Wi-Fi networks with similar names appear (e.g. 'Cafe_Free_Wifi' vs 'Cafe_Wifi_Free').",
            "Your phone warns that Developer Mode or USB Debugging is turned on without your knowledge."
        ],
        "recommended_actions": [
            "Turn off Wi-Fi and use your mobile cellular data when making payments or opening bank apps.",
            "Turn off 'Auto-connect to open Wi-Fi networks' in phone settings.",
            "Keep your phone software and security updates up to date.",
            "Turn off Developer Options and USB Debugging when not in use."
        ],
        "prevention_tips": [
            "Use mobile data (4G/5G) for banking; it is much safer than public hotspots.",
            "Set a screen lock (fingerprint, pattern, or PIN) so nobody can access your phone if lost.",
            "Never leave your phone unattended with strangers."
        ],
        "keywords": ["wifi", "device", "public wifi", "bluetooth", "developer options", "usb", "settings", "phone"],
        "related_event_types": ["device"],
        "icon_name": "wifi"
    },
    {
        "id": "social_engineering",
        "title": "False Urgency & Emotional Pressure",
        "category": "Common Threats",
        "description": "Scammers create panic or extreme excitement to make you act quickly before you have time to think or ask family members.",
        "risk_level": "high",
        "how_scammers_do_it": "A caller claims to be a police officer, customs official, or hospital doctor. They say your child or relative has been arrested or met with an accident, and you must send money immediately to save them or pay bail.",
        "warning_signs": [
            "Extreme urgency: 'Send money within 10 minutes or it will be too late!'.",
            "They tell you: 'Do NOT tell anyone, keep this confidential'.",
            "Demanding immediate transfer via UPI or gift cards instead of following legal procedure.",
            "Caller sounds stressed, aggressive, or authoritatively demanding."
        ],
        "recommended_actions": [
            "Take a deep breath and PAUSE. Do not transfer any money immediately.",
            "Call your family member or child directly on their known phone number to verify their safety.",
            "Ask a family member or trusted neighbor to listen to the call.",
            "Real police and government officers never demand money transfers over the phone."
        ],
        "prevention_tips": [
            "Whenever someone demands money urgently, STOP and talk to someone you trust.",
            "Scammers rely on your fear and hurry. Slowing down always protects you.",
            "Save official local police station numbers in your contacts."
        ],
        "keywords": ["urgency", "police", "arrest", "scam", "pressure", "accident", "fear", "threat", "emergency"],
        "related_event_types": ["sms"],
        "icon_name": "warning"
    },
    {
        "id": "suspicious_emails",
        "title": "Suspicious Emails & Fake Invoices",
        "category": "Email & Messages",
        "description": "Scam emails pretend to be from tax departments, banks, or online stores sending unexpected bills, invoices, or prizes.",
        "risk_level": "medium",
        "how_scammers_do_it": "You receive an email claiming: 'Invoice for your purchase of Rs. 45,000 attached. If you did not make this order, call this number immediately'. When you open the attachment or call, they attempt to steal your payment details.",
        "warning_signs": [
            "Sender email address looks strange (e.g. support@bank-security192.com instead of the real bank domain).",
            "Attachments ending with .zip, .exe, or .apk.",
            "Generic greetings like 'Dear Customer' instead of your real name.",
            "Threats of legal action or account termination."
        ],
        "recommended_actions": [
            "Do not download or open any attachments.",
            "Do not click any buttons or links inside the email.",
            "Mark the email as Spam / Phishing in your email app.",
            "If you are concerned about your account, check directly inside your official banking or shopping app."
        ],
        "prevention_tips": [
            "Always inspect the sender’s full email address, not just the display name.",
            "Never enable macros or permissions if a downloaded document asks for them.",
            "Official companies address you by your registered account name."
        ],
        "keywords": ["email", "invoice", "attachment", "bill", "spam", "phishing", "tax", "order"],
        "related_event_types": ["email"],
        "icon_name": "email"
    },
    {
        "id": "privacy_protection",
        "title": "Privacy & Social Media Sharing",
        "category": "Privacy",
        "description": "Sharing your location, phone number, and daily routine publicly on social media makes it easy for scammers to target you.",
        "risk_level": "low",
        "how_scammers_do_it": "Fraudsters look at public profiles on Facebook or Instagram to find your phone number, friends, family members, and where you travel. They use these details to call you and pretend to be your friend or acquaintance.",
        "warning_signs": [
            "Friend requests from people you are already friends with (cloned profiles).",
            "Strangers messaging you asking personal questions about your family or job.",
            "Quizzes or games on social media asking for your mother’s maiden name or birthplace."
        ],
        "recommended_actions": [
            "Change your social media profile privacy settings to 'Friends Only'.",
            "Hide your phone number and email address from public view.",
            "Never accept friend requests from duplicate or unverified accounts."
        ],
        "prevention_tips": [
            "Avoid posting photos of travel tickets, boarding passes, or identity documents.",
            "Turn off location sharing for apps that do not require it.",
            "Regularly review which third-party apps have access to your accounts."
        ],
        "keywords": ["privacy", "social media", "facebook", "instagram", "profile", "personal info", "data"],
        "related_event_types": ["device"],
        "icon_name": "shield"
    }
]

class KnowledgeService:
    @staticmethod
    def seed_initial_data(db: Session):
        """Seed database with all verified knowledge entries if missing."""
        existing_entries = {e.id for e in db.query(KnowledgeEntryModel.id).all()}
        for item in SEED_ENTRIES:
            if item["id"] not in existing_entries:
                entry = KnowledgeEntryModel(
                    id=item["id"],
                    title=item["title"],
                    category=item["category"],
                    description=item["description"],
                    risk_level=item["risk_level"],
                    how_scammers_do_it=item["how_scammers_do_it"],
                    warning_signs_json=json.dumps(item["warning_signs"]),
                    recommended_actions_json=json.dumps(item["recommended_actions"]),
                    prevention_tips_json=json.dumps(item["prevention_tips"]),
                    keywords_json=json.dumps(item["keywords"]),
                    related_event_types_json=json.dumps(item["related_event_types"]),
                    icon_name=item["icon_name"],
                )
                db.add(entry)
        db.commit()

    @staticmethod
    def get_all(db: Session) -> List[dict]:
        entries = db.query(KnowledgeEntryModel).all()
        return [e.to_dict() for e in entries]

    @staticmethod
    def get_by_id(db: Session, entry_id: str) -> Optional[dict]:
        entry = db.query(KnowledgeEntryModel).filter(KnowledgeEntryModel.id == entry_id).first()
        return entry.to_dict() if entry else None

    @staticmethod
    def get_by_category(db: Session, category: str) -> List[dict]:
        clean_cat = category.strip().lower()
        entries = db.query(KnowledgeEntryModel).all()
        matches = [e.to_dict() for e in entries if e.category.lower() == clean_cat]
        return matches

    @staticmethod
    def search(db: Session, query: str) -> List[dict]:
        clean_query = query.strip().lower()
        entries = db.query(KnowledgeEntryModel).all()
        if not clean_query:
            return [e.to_dict() for e in entries]

        results = []
        for e in entries:
            d = e.to_dict()
            if (clean_query in d["title"].lower() or
                clean_query in d["category"].lower() or
                clean_query in d["description"].lower() or
                any(clean_query in kw.lower() for kw in d["keywords"]) or
                any(clean_query in ws.lower() for ws in d["warningSigns"])):
                results.append(d)
        return results
