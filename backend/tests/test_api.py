import os
import sys

# Ensure backend directory is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from fastapi.testclient import TestClient
from app.main import app
from app.database import Base, engine, SessionLocal
from app.services.knowledge_service import KnowledgeService

client = TestClient(app)

def setup_module():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        KnowledgeService.seed_initial_data(db)
    finally:
        db.close()

def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert data["service"] == "SecureSphere API"

def test_get_all_knowledge():
    response = client.get("/api/knowledge")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "items" in data
    assert data["total"] >= 12
    ids = [item["id"] for item in data["items"]]
    assert "device_wifi_safety" in ids
    assert "social_engineering" in ids
    assert "suspicious_emails" in ids
    assert "privacy_protection" in ids

def test_search_knowledge():
    response = client.get("/api/knowledge/search?q=OTP")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert any("otp" in item["id"].lower() for item in data["items"])

def test_threat_analysis_url():
    payload = {
        "type": "url",
        "content": "http://192.168.1.1/login-banking-verify.xyz"
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["threatType"] == "url_threat"
    assert data["riskLevel"] == "high"
    assert data["riskScore"] >= 60
    assert len(data["indicators"]) > 0

def test_threat_analysis_sms_otp():
    payload = {
        "type": "sms",
        "content": "ALERT: Your bank account will be blocked. Share your 6-digit OTP immediately."
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["threatType"] == "sms_scam"
    assert data["riskLevel"] == "high"
    assert any("otp" in ind.lower() for ind in data["indicators"])

# --- A. Existing Functionality: App, Email, and Risk Thresholds ---
def test_threat_analysis_app():
    payload = {
        "type": "app",
        "content": "QuickLoan.apk installed from unknown browser source requesting SMS and accessibility."
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["threatType"] == "app_malware"
    assert data["riskLevel"] == "high"
    assert data["riskScore"] >= 60

def test_threat_analysis_email():
    payload = {
        "type": "email",
        "content": "FINAL NOTICE: Overdue invoice attached. Open invoice_doc.zip immediately to prevent legal action."
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["threatType"] == "phishing_email"
    assert data["riskLevel"] == "high"
    assert data["riskScore"] >= 60

def test_threat_analysis_risk_thresholds():
    # Low Risk
    res_low = client.post("/api/threat/analyze", json={"type": "url", "content": "https://google.com"})
    assert res_low.status_code == 200
    assert res_low.json()["riskLevel"] == "low"
    assert res_low.json()["riskScore"] < 25

    # Medium Risk (e.g. unencrypted link with shortener)
    res_med = client.post("/api/threat/analyze", json={"type": "url", "content": "http://bit.ly/newsletter"})
    assert res_med.status_code == 200
    assert res_med.json()["riskLevel"] == "medium"
    assert 25 <= res_med.json()["riskScore"] < 60

# --- B. Knowledge Correlation Tests ---
def test_knowledge_correlation_otp_sms():
    payload = {
        "type": "sms",
        "content": "Your SBI account is locked. Read out your 6-digit OTP code to verify your identity."
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "relatedKnowledgeEntries" in data
    assert len(data["relatedKnowledgeEntries"]) > 0
    assert data["relatedKnowledgeEntries"][0]["id"] == "otp_scam"

def test_knowledge_correlation_upi_sms():
    payload = {
        "type": "sms",
        "content": "Rs. 5,000 received! Scan this QR code and approve PhonePe UPI collect request to claim."
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "relatedKnowledgeEntries" in data
    assert any(k["id"] == "upi_scam" for k in data["relatedKnowledgeEntries"])

def test_knowledge_correlation_phishing_url():
    payload = {
        "type": "url",
        "content": "http://192.168.1.1/update-kyc-banking.xyz"
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "relatedKnowledgeEntries" in data
    assert any(k["id"] == "phishing_links" for k in data["relatedKnowledgeEntries"])

def test_knowledge_correlation_suspicious_apk():
    payload = {
        "type": "app",
        "content": "Unknown source app downloaded as cash_loan.apk requesting contacts"
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "relatedKnowledgeEntries" in data
    assert any(k["id"] == "fake_apps" for k in data["relatedKnowledgeEntries"])

# --- C. Device Security Analysis Tests ---
def test_device_analysis_safe():
    payload = {
        "type": "device",
        "content": "Device integrity check passed. Screen lock active, no root.",
        "metadata": {
            "screen_lock_enabled": True,
            "usb_debugging_enabled": False,
            "developer_options_enabled": False,
            "is_rooted": False
        }
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["threatType"] == "device_security_threat"
    assert data["riskLevel"] == "low"
    assert data["riskScore"] < 25

def test_device_analysis_usb_debugging_elevated_risk():
    payload = {
        "type": "device",
        "content": "Device status alert",
        "metadata": {
            "usb_debugging_enabled": True
        }
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["threatType"] == "device_security_threat"
    assert data["riskLevel"] == "medium"
    assert 25 <= data["riskScore"] < 60
    assert any("usb debugging" in ind.lower() for ind in data["indicators"])

def test_device_analysis_developer_options_elevated_risk():
    payload = {
        "type": "device",
        "content": "Developer options are enabled on user phone",
        "metadata": {
            "developer_options_enabled": True
        }
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["riskLevel"] == "medium"
    assert 25 <= data["riskScore"] < 60

def test_device_analysis_multiple_problems_high_risk():
    payload = {
        "type": "device",
        "content": "Device check",
        "metadata": {
            "usb_debugging_enabled": True,
            "screen_lock_disabled": True,
            "unknown_sources_enabled": True
        }
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["riskLevel"] == "high"
    assert data["riskScore"] >= 60
    assert len(data["indicators"]) >= 3

def test_device_analysis_root_jailbreak_high_risk():
    payload = {
        "type": "device",
        "content": "Root detected: su binary found in /system/bin",
        "metadata": {
            "is_rooted": True
        }
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["riskLevel"] == "high"
    assert data["riskScore"] >= 60
    assert any("root" in ind.lower() for ind in data["indicators"])

# --- D. Response Compatibility Tests ---
def test_response_compatibility_fields():
    payload = {
        "type": "sms",
        "content": "Urgent verification needed"
    }
    response = client.post("/api/threat/analyze", json=payload)
    assert response.status_code == 200
    data = response.json()
    required_fields = [
        "id", "threatType", "riskLevel", "riskScore",
        "confidence", "reason", "indicators", "recommendedAction",
        "timestamp", "relatedKnowledgeEntries"
    ]
    for field in required_fields:
        assert field in data, f"Missing field: {field}"
    assert isinstance(data["relatedKnowledgeEntries"], list)
    if len(data["relatedKnowledgeEntries"]) > 0:
        entry = data["relatedKnowledgeEntries"][0]
        assert "id" in entry
        assert "title" in entry
        assert "category" in entry
        assert "howScammersDoIt" in entry
        assert "recommendedActions" in entry
