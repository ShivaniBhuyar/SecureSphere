import httpx
from typing import Optional, Dict, Any
from app.config import settings

class ExternalSecurityService:
    """
    Integrates external threat intelligence APIs (VirusTotal, Google Safe Browsing).
    All API keys are securely read from backend environment variables.
    """

    @staticmethod
    async def check_virustotal_url(url: str) -> Optional[Dict[str, Any]]:
        """Query VirusTotal API v3 for URL analysis if API key is configured."""
        if not settings.VIRUSTOTAL_API_KEY:
            return None

        headers = {
            "x-apikey": settings.VIRUSTOTAL_API_KEY,
            "Accept": "application/json",
        }
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # VirusTotal requires base64 URL identifier without padding
                import base64
                url_id = base64.urlsafe_b64encode(url.encode()).decode().strip("=")
                response = await client.get(
                    f"https://www.virustotal.com/api/v3/urls/{url_id}",
                    headers=headers
                )
                if response.status_code == 200:
                    data = response.json()
                    stats = data.get("data", {}).get("attributes", {}).get("last_analysis_stats", {})
                    malicious = stats.get("malicious", 0)
                    suspicious = stats.get("suspicious", 0)
                    return {
                        "malicious": malicious,
                        "suspicious": suspicious,
                        "is_threat": (malicious + suspicious) > 0,
                    }
        except Exception:
            return None
        return None

    @staticmethod
    async def check_google_safe_browsing(url: str) -> Optional[Dict[str, Any]]:
        """Query Google Safe Browsing Lookup API if API key is configured."""
        if not settings.GOOGLE_SAFE_BROWSING_KEY:
            return None

        endpoint = f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={settings.GOOGLE_SAFE_BROWSING_KEY}"
        payload = {
            "client": {"clientId": "securesphere-backend", "clientVersion": "1.0.0"},
            "threatInfo": {
                "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
                "platformTypes": ["ANY_PLATFORM"],
                "threatEntryTypes": ["URL"],
                "threatEntries": [{"url": url}],
            },
        }
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.post(endpoint, json=payload)
                if response.status_code == 200:
                    matches = response.json().get("matches", [])
                    return {
                        "has_match": len(matches) > 0,
                        "matches": matches,
                    }
        except Exception:
            return None
        return None
