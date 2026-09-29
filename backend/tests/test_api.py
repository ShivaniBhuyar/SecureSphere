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
