import re
import uuid
from datetime import datetime
from typing import Dict, Any, List
from sqlalchemy.orm import Session
import json

from app.models.threat_log import ThreatLogModel
from app.services.external_security import ExternalSecurityService

class ThreatAnalyzerService:
    @staticmethod
    async def analyze(db: Session, event_type: str, content: str, metadata: dict = None) -> Dict[str, Any]:
        clean_type = event_type.lower().strip()
        text = content.lower()
        score = 0
        indicators: List[str] = []
        threat_type = "normal_activity"

        # 1. URL Analysis
        if clean_type == "url":
            threat_type = "url_threat"
            # External checks
            vt_res = await ExternalSecurityService.check_virustotal_url(content)
            if vt_res and vt_res.get("is_threat"):
                score += 80
                indicators.append(f"Flagged as malicious by VirusTotal intelligence ({vt_res.get('malicious')} vendor detections).")

            gsb_res = await ExternalSecurityService.check_google_safe_browsing(content)
            if gsb_res and gsb_res.get("has_match"):
                score += 80
                indicators.append("Flagged as malicious by Google Safe Browsing.")

            # Pattern checks
            if re.search(r'https?:\/\/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', text):
                score += 55
                indicators.append("URL uses an IP address instead of a genuine domain name.")

            if re.search(r'\.(xyz|top|ru|work|click|loan|zip)\b', text):
                score += 35
                indicators.append("URL uses a suspicious high-risk top-level domain.")

            if re.search(r'(bit\.ly|tinyurl|t\.co|goo\.gl)', text):
                score += 25
                indicators.append("Shortened link disguising the true destination.")

            if re.search(r'(login|verify|account|bank|secure|update|otp)', text):
                score += 25
                indicators.append("URL contains sensitive banking or credential harvesting keywords.")

            if text.startswith("http://"):
                score += 15
                indicators.append("Connection is unencrypted (HTTP instead of HTTPS).")

        # 2. SMS Analysis
        elif clean_type == "sms":
            threat_type = "sms_scam"
            if re.search(r'\b(otp|one[-\s]?time[-\s]?password|verification[-\s]?code|pin)\b', text):
                score += 40
                indicators.append("Message asks for a secret OTP or verification code.")

            if re.search(r'\b(blocked|suspended|deactivated|urgent|immediately|act now)\b', text):
                score += 30
                indicators.append("Message creates false panic threatening account suspension.")

            if re.search(r'\b(kyc|pan[-\s]?card|aadhaar|debit[-\s]?card|cvv|account)\b', text):
                score += 25
                indicators.append("Message requests sensitive banking or identity credentials.")

            if re.search(r'\b(won|prize|lottery|reward|claim now|free cash)\b', text):
                score += 30
                indicators.append("Message promises fraudulent prizes or lottery winnings.")

            if re.search(r'(https?:\/\/|bit\.ly|\.xyz|\.top|\.apk)', text):
                score += 25
                indicators.append("Message contains an unverified external link or APK.")

        # 3. App / APK Analysis
        elif clean_type == "app":
            threat_type = "app_malware"
            if ".apk" in text or "unknown" in text:
                score += 45
                indicators.append("Application was downloaded as an APK from an unverified source.")

            if "sms" in text or "contacts" in text or "accessibility" in text:
                score += 35
                indicators.append("Application requests critical sensitive device permissions.")

        # 4. Email Analysis
        elif clean_type == "email":
            threat_type = "phishing_email"
            if re.search(r'(invoice|payment overdue|tax refund|legal action)', text):
                score += 40
                indicators.append("Email creates false financial or legal panic.")
            if re.search(r'(\.zip|\.exe|\.apk)', text):
                score += 45
                indicators.append("Email contains potentially dangerous attachment.")

        # 5. Device Security Analysis
        elif clean_type == "device":
            threat_type = "device_security_threat"
            meta = metadata or {}

            def has_signal(meta_keys: List[str], regex_pattern: str, negative_pattern: str = None) -> bool:
                for k in meta_keys:
                    if k in meta:
                        val = meta.get(k)
                        if val is True or (isinstance(val, str) and val.lower() in ["true", "enabled", "1", "yes"]):
                            return True
                        elif val is False or (isinstance(val, str) and val.lower() in ["false", "disabled", "0", "no"]):
                            return False
                if negative_pattern and re.search(negative_pattern, text):
                    return False
                return bool(re.search(regex_pattern, text))

            def has_negative_signal(disabled_keys: List[str], enabled_keys: List[str], regex_pattern: str, negative_pattern: str = None) -> bool:
                for k in disabled_keys:
                    if k in meta:
                        val = meta.get(k)
                        if val is True or (isinstance(val, str) and val.lower() in ["true", "disabled", "1", "yes"]):
                            return True
                        elif val is False or (isinstance(val, str) and val.lower() in ["false", "enabled", "0", "no"]):
                            return False
                for k in enabled_keys:
                    if k in meta:
                        val = meta.get(k)
                        if val is False or (isinstance(val, str) and val.lower() in ["false", "disabled", "0", "no"]):
                            return True
                        elif val is True or (isinstance(val, str) and val.lower() in ["true", "enabled", "1", "yes"]):
                            return False
                if negative_pattern and re.search(negative_pattern, text):
                    return False
                return bool(re.search(regex_pattern, text))

            # 1. Root / Jailbreak (Critical Risk)
            if has_signal(
                ["is_rooted", "root_detected", "jailbreak", "rooted"],
                r'\b(root|rooted|jailbreak|jailbroken|magisk|superuser|su binary)\b',
                r'\b(no[-\s]?root|not[-\s]?rooted|unrooted)\b'
            ):
                score += 60
                indicators.append("Device is rooted or jailbroken, compromising OS sandboxing and system security.")

            # 2. Screen lock disabled (Medium Risk)
            if has_negative_signal(
                ["screen_lock_disabled", "no_screen_lock"],
                ["screen_lock_enabled", "is_screen_lock_enabled", "lock_screen_enabled"],
                r'\b(screen[-\s]?lock[-\s]?(disabled|off|none)|no[-\s]?lock[-\s]?screen|lock screen is disabled)\b',
                r'\b(screen[-\s]?lock[-\s]?(active|enabled|on)|lock[-\s]?screen[-\s]?(active|enabled|on))\b'
            ):
                score += 30
                indicators.append("Device screen lock (PIN, Password, or Biometrics) is disabled, leaving physical access unprotected.")

            # 3. USB Debugging enabled (Medium Risk)
            if has_signal(
                ["usb_debugging_enabled", "usb_debugging", "adb_enabled"],
                r'\b(usb[-\s]?debugging|adb[-\s]?(enabled|debugging))\b',
                r'\b(usb[-\s]?debugging[-\s]?(disabled|off)|no[-\s]?usb[-\s]?debugging)\b'
            ):
                score += 30
                indicators.append("USB Debugging is enabled, allowing unauthorized computer access and remote execution.")

            # 4. Developer options enabled (Elevated / Medium Risk)
            if has_signal(
                ["developer_options_enabled", "developer_mode", "development_settings_enabled"],
                r'\b(developer[-\s]?(options|mode|settings)|developer options are enabled)\b',
                r'\b(developer[-\s]?(options|mode|settings)[-\s]?(disabled|off))\b'
            ):
                score += 15 if any("USB Debugging" in ind for ind in indicators) else 25
                indicators.append("Developer options are enabled, exposing internal debugging interfaces.")

            # 5. Unknown source installation enabled (Medium Risk)
            if has_signal(["unknown_sources_enabled", "allow_unknown_apps", "install_unknown_apps_enabled"], r'\b(unknown[-\s]?(sources|apps)|sideloading[-\s]?enabled|allow unknown apps)\b'):
                score += 30
                indicators.append("Installation from unknown sources is enabled, allowing unverified third-party APK installations.")

            # 6. Mock locations enabled (Elevated Risk)
            if has_signal(["mock_location_enabled", "mock_locations_enabled"], r'\b(mock[-\s]?locations?|fake[-\s]?gps)\b'):
                score += 25
                indicators.append("Mock location provider is active, allowing GPS spoofing.")

            # 7. Device security warning signal
            if has_signal(["device_security_warning", "security_warning"], r'\b(security[-\s]?warning|tampered|integrity[-\s]?failed)\b'):
                score += 35
                indicators.append("System reported a device integrity or security warning.")

        # 6. Fallback baseline
        if not indicators:
            score = 5
            indicators.append("No suspicious indicators detected." if clean_type != "device" else "No suspicious device security anomalies detected.")

        score = min(100, max(0, score))

        # Risk level determination
        if score >= 60:
            risk_level = "high"
            reason = f"High probability of cyber threat ({clean_type.upper()}). Strong fraud indicators identified." if clean_type != "device" else "High risk device security vulnerability. Immediate remediation required."
            recommended_action = "Do not click links, share codes, or approve payments. Verify through official channels." if clean_type != "device" else "Disable dangerous settings, unroot device if necessary, and enable biometric or screen lock."
            confidence = 0.94
        elif score >= 25:
            risk_level = "medium"
            reason = f"Potential risk detected ({clean_type.upper()}). Some suspicious attributes present." if clean_type != "device" else "Elevated device security risk. Some developer or unverified settings are enabled."
            recommended_action = "Proceed with caution. Check sender identity and avoid entering personal details." if clean_type != "device" else "Review device settings and disable unnecessary developer or debugging options."
            confidence = 0.85
        else:
            risk_level = "low"
            reason = "Content appears normal and safe." if clean_type != "device" else "Device security configuration appears normal and safe."
            recommended_action = "No action required. Use standard online precautions." if clean_type != "device" else "Maintain current device protection and keep operating system updated."
            confidence = 0.98

        result_id = str(uuid.uuid4())
        now = datetime.utcnow()

        # Log audit entry to database
        try:
            log_entry = ThreatLogModel(
                id=result_id,
                event_type=clean_type,
                content_snippet=content[:450],
                threat_type=threat_type,
                risk_level=risk_level,
                risk_score=score,
                confidence=confidence,
                reason=reason,
                indicators_json=json.dumps(indicators),
                recommended_action=recommended_action,
                timestamp=now,
            )
            db.add(log_entry)
            db.commit()
        except Exception:
            db.rollback()

        # Knowledge Base Correlation Step
        related_knowledge = ThreatAnalyzerService.correlate_knowledge(
            db=db,
            event_type=clean_type,
            content=content,
            indicators=indicators,
            threat_type=threat_type,
            risk_level=risk_level,
        )

        return {
            "id": result_id,
            "threatType": threat_type,
            "riskLevel": risk_level,
            "confidence": confidence,
            "reason": reason,
            "riskScore": score,
            "indicators": indicators,
            "recommendedAction": recommended_action,
            "timestamp": now.isoformat(),
            "relatedKnowledgeEntries": related_knowledge,
        }

    @classmethod
    def correlate_knowledge(
        cls,
        db: Session,
        event_type: str,
        content: str,
        indicators: List[str],
        threat_type: str,
        risk_level: str
    ) -> List[Dict[str, Any]]:
        """
        Correlates detected threat signals and event context with the verified Knowledge Base entries.
        Matches entries based on event type, indicators, keywords, and threat categories.
        """
        try:
            from app.models.knowledge import KnowledgeEntryModel
            entries = db.query(KnowledgeEntryModel).all()
            if not entries:
                from app.services.knowledge_service import KnowledgeService
                KnowledgeService.seed_initial_data(db)
                entries = db.query(KnowledgeEntryModel).all()

            entries_by_id = {e.id: e.to_dict() for e in entries}
            combined_text = f"{content} {' '.join(indicators)} {threat_type} {event_type}".lower()

            matched_ids: List[str] = []

            # 1. OTP / Secret verification code
            if (
                event_type != "device"
                and any(k in combined_text for k in ["otp", "one-time", "one time", "verification code", "secret pin"])
                and "otp_scam" in entries_by_id
            ):
                matched_ids.append("otp_scam")

            # 2. UPI / QR code / payment collect request
            if (
                any(k in combined_text for k in ["upi", "qr", "phonepe", "gpay", "paytm", "collect request", "payment offer"])
                and "upi_scam" in entries_by_id
            ):
                matched_ids.append("upi_scam")

            # 3. Phishing Links / URLs / Malicious domains
            if (
                (event_type == "url" or any(k in combined_text for k in ["url", "link", "phish", ".xyz", ".top", "shortened", "virustotal", "safe browsing", "fake login"]))
                and "phishing_links" in entries_by_id
            ):
                matched_ids.append("phishing_links")

            # 4. Dangerous APKs / Fake Apps / Sensitive Permissions
            if (
                (event_type == "app" or any(k in combined_text for k in ["apk", "sideload", "fake app", "unknown source", "accessibility", "loan app", "spyware"]))
                and "fake_apps" in entries_by_id
            ):
                matched_ids.append("fake_apps")

            # 5. Fake Customer Care / Bank Official
            if (
                any(k in combined_text for k in ["customer care", "bank official", "electricity officer", "executive", "anydesk", "teamviewer"])
                and "fake_customer_care" in entries_by_id
            ):
                matched_ids.append("fake_customer_care")

            # 6. False Urgency / Panic / Social Engineering
            if (
                any(k in combined_text for k in ["urgent", "immediately", "blocked", "suspended", "deactivated", "act now", "arrest", "lottery", "won"])
                and "social_engineering" in entries_by_id
            ):
                matched_ids.append("social_engineering")

            # 7. Identity Theft / KYC / Aadhaar / PAN
            if (
                any(k in combined_text for k in ["kyc", "pan card", "pan-card", "aadhaar", "identity", "passport"])
                and "identity_theft" in entries_by_id
            ):
                matched_ids.append("identity_theft")

            # 8. Device / Wi-Fi / Developer Options / USB Debugging / Root
            if (
                (event_type == "device" or any(k in combined_text for k in ["usb debugging", "developer options", "root", "jailbreak", "mock location", "wi-fi", "wifi", "lock screen"]))
                and "device_wifi_safety" in entries_by_id
            ):
                matched_ids.append("device_wifi_safety")

            # 9. Password Security
            if (
                any(k in combined_text for k in ["password", "passcode", "credentials", "login details"])
                and "password_security" in entries_by_id
            ):
                matched_ids.append("password_security")

            # 10. Suspicious Emails
            if (
                (event_type == "email" or any(k in combined_text for k in ["invoice", "overdue", "email attachment"]))
                and "suspicious_emails" in entries_by_id
            ):
                matched_ids.append("suspicious_emails")

            # 11. Suspicious Messages
            if (
                (event_type == "sms" or any(k in combined_text for k in ["whatsapp", "telegram", "message"]))
                and "suspicious_messages" in entries_by_id
            ):
                matched_ids.append("suspicious_messages")

            # 12. Privacy Protection
            if (
                any(k in combined_text for k in ["privacy", "social media", "facebook", "instagram", "personal info"])
                and "privacy_protection" in entries_by_id
            ):
                matched_ids.append("privacy_protection")

            # Deduplicate while preserving order
            unique_ids: List[str] = []
            for mid in matched_ids:
                if mid not in unique_ids:
                    unique_ids.append(mid)

            # Fallback by relatedEventTypes if no specific rule triggered
            if not unique_ids:
                for eid, edict in entries_by_id.items():
                    rel_types = [t.lower() for t in edict.get("relatedEventTypes", [])]
                    if event_type in rel_types:
                        unique_ids.append(eid)
                        break

            # If still empty, fallback to social_engineering or first entry
            if not unique_ids:
                if "social_engineering" in entries_by_id:
                    unique_ids.append("social_engineering")
                elif entries_by_id:
                    unique_ids.append(list(entries_by_id.keys())[0])

            return [entries_by_id[uid] for uid in unique_ids[:3] if uid in entries_by_id]
        except Exception:
            return []
