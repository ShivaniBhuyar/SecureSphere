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

        # 5. Fallback baseline
        if not indicators:
            score = 5
            indicators.append("No suspicious indicators detected.")

        score = min(100, max(0, score))

        # Risk level determination
        if score >= 60:
            risk_level = "high"
            reason = f"High probability of cyber threat ({clean_type.upper()}). Strong fraud indicators identified."
            recommended_action = "Do not click links, share codes, or approve payments. Verify through official channels."
            confidence = 0.94
        elif score >= 25:
            risk_level = "medium"
            reason = f"Potential risk detected ({clean_type.upper()}). Some suspicious attributes present."
            recommended_action = "Proceed with caution. Check sender identity and avoid entering personal details."
            confidence = 0.85
        else:
            risk_level = "low"
            reason = "Content appears normal and safe."
            recommended_action = "No action required. Use standard online precautions."
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
        }
