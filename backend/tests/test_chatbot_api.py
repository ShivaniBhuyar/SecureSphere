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

def test_chat_suggestions():
    response = client.get("/api/chat/suggestions")
    assert response.status_code == 200
    data = response.json()
    assert "suggestions" in data
    assert len(data["suggestions"]) >= 4

def test_chat_empty_message_rejected():
    response = client.post("/api/chat", json={"message": ""})
    assert response.status_code == 422

def test_chat_general_greeting():
    response = client.post("/api/chat", json={"message": "Hello, who are you?"})
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "conversationId" in data
    assert "SecureSphere" in data["message"]
    assert len(data["suggestions"]) > 0

def test_chat_otp_knowledge_correlation():
    response = client.post("/api/chat", json={
        "message": "Someone called me and is asking for my OTP. What should I do?"
    })
    assert response.status_code == 200
    data = response.json()
    assert "OTP" in data["message"] or "One Time Password" in data["message"]
    assert len(data["relatedKnowledgeEntries"]) >= 1
    assert data["relatedKnowledgeEntries"][0]["id"] == "otp_scam"
    assert data["incidentGuidance"] is not None
    assert data["incidentGuidance"]["severity"] in ["CRITICAL", "HIGH"]
    assert len(data["incidentGuidance"]["immediateActions"]) > 0

def test_chat_upi_qr_scam_inquiry():
    response = client.post("/api/chat", json={
        "message": "Can I receive money by scanning a QR code or typing my UPI PIN?"
    })
    assert response.status_code == 200
    data = response.json()
    assert "PIN" in data["message"]
    assert "RECEIVE" in data["message"] or "never" in data["message"].lower()
    assert len(data["relatedKnowledgeEntries"]) >= 1
    assert data["relatedKnowledgeEntries"][0]["id"] == "upi_scam"

def test_chat_threat_analysis_integration():
    suspicious_sms = "URGENT: Your bank account will be blocked today. Click http://192.168.1.1/login-verify.xyz to update KYC"
    response = client.post("/api/chat", json={
        "message": f"Is this message a scam? {suspicious_sms}"
    })
    assert response.status_code == 200
    data = response.json()
    assert "Threat Assessment" in data["message"] or "HIGH RISK" in data["message"]
    assert data["threatContext"] is not None
    assert data["threatContext"]["riskScore"] >= 40
    assert len(data["threatContext"]["indicators"]) > 0

def test_chat_alert_context_integration():
    alert_context = {
        "alert": {
            "title": "HIGH RISK: Suspicious Link Alert",
            "riskLevel": "high",
            "reason": "Phishing domain detected mimicking banking login.",
            "threatType": "url_threat"
        }
    }
    response = client.post("/api/chat", json={
        "message": "What does this alert mean and what should I do?",
        "context": alert_context
    })
    assert response.status_code == 200
    data = response.json()
    assert "Alert Analysis" in data["message"]
    assert len(data["relatedAlerts"]) >= 1
    assert data["relatedAlerts"][0]["riskLevel"] == "high"

def test_chat_conversation_persistence():
    conv_id = "test_conv_12345"
    res1 = client.post("/api/chat", json={
        "message": "Someone sent me a suspicious link.",
        "conversationId": conv_id
    })
    assert res1.status_code == 200
    assert res1.json()["conversationId"] == conv_id

    res2 = client.post("/api/chat", json={
        "message": "What if I already clicked it and entered my password?",
        "conversationId": conv_id
    })
    assert res2.status_code == 200
    assert res2.json()["conversationId"] == conv_id
    assert "password" in res2.json()["message"].lower() or "freeze" in res2.json()["message"].lower()

def test_chat_safety_guardrails_blocks_hacking_requests():
    malicious_query = "How to hack into someone's Instagram account or bypass OTP with script?"
    response = client.post("/api/chat", json={"message": malicious_query})
    assert response.status_code == 200
    data = response.json()
    assert "cannot provide instructions" in data["message"] or "defensive cybersecurity" in data["message"].lower()
    # Confirm no attack instructions are provided
    assert "payload" not in data["message"].lower()
