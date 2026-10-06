import os
import sys
import uuid
from datetime import datetime, timedelta
import json
import pytest
from fastapi.testclient import TestClient

# Ensure backend directory is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from app.main import app
from app.database import Base, engine, SessionLocal
from app.models.threat_log import ThreatLogModel
from app.models.alert import AlertModel

client = TestClient(app)

TEST_LOG_IDS = []

def setup_module():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    now = datetime.utcnow()
    try:
        # Seed test logs
        test_logs = [
            ThreatLogModel(
                id=f"test-rep-{uuid.uuid4()}",
                event_type="sms",
                content_snippet="Your bank account is locked, submit OTP immediately",
                threat_type="sms_scam",
                risk_level="high",
                risk_score=85,
                confidence=0.92,
                reason="High-risk banking OTP phishing message",
                indicators_json=json.dumps(["Requests OTP code", "Creates false urgency"]),
                recommended_action="Never share OTP with anyone.",
                timestamp=now - timedelta(days=1),
            ),
            ThreatLogModel(
                id=f"test-rep-{uuid.uuid4()}",
                event_type="url",
                content_snippet="http://192.168.1.1/fake-login",
                threat_type="url_threat",
                risk_level="medium",
                risk_score=50,
                confidence=0.88,
                reason="Unencrypted IP address URL with credential prompts",
                indicators_json=json.dumps(["Uses raw IP address", "Unencrypted HTTP"]),
                recommended_action="Do not open unverified links.",
                timestamp=now - timedelta(days=2),
            ),
            ThreatLogModel(
                id=f"test-rep-{uuid.uuid4()}",
                event_type="device",
                content_snippet="Device security audit",
                threat_type="device_security_threat",
                risk_level="low",
                risk_score=10,
                confidence=0.95,
                reason="Device security configuration appears normal",
                indicators_json=json.dumps(["No suspicious device security anomalies detected."]),
                recommended_action="Maintain current protection.",
                timestamp=now - timedelta(hours=2),
            ),
        ]
        for l in test_logs:
            db.add(l)
            TEST_LOG_IDS.append(l.id)
        db.commit()
    finally:
        db.close()

def teardown_module():
    db = SessionLocal()
    try:
        for tid in TEST_LOG_IDS:
            db.query(ThreatLogModel).filter(ThreatLogModel.id == tid).delete()
        db.commit()
    finally:
        db.close()

def test_get_report_summary():
    response = client.get("/api/reports/summary?days=7")
    assert response.status_code == 200
    data = response.json()
    assert "totalScans" in data
    assert data["totalScans"] >= 3
    assert "threatsDetected" in data
    assert "securityPosture" in data
    assert data["securityPosture"] in ["Excellent", "Good", "Needs Attention", "Critical Risk"]
    assert "averageRiskScore" in data
    assert "eventTypeBreakdown" in data
    assert "threatTypeBreakdown" in data
    assert "recommendedActions" in data
    assert len(data["recommendedActions"]) > 0

def test_get_report_summary_all_time():
    response = client.get("/api/reports/summary?days=0")
    assert response.status_code == 200
    data = response.json()
    assert data["timeframeDays"] is None
    assert data["totalScans"] >= 3

def test_get_threat_history_default():
    response = client.get("/api/reports/history?limit=10&offset=0")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "items" in data
    assert len(data["items"]) <= 10
    assert data["total"] >= 3
    item = data["items"][0]
    assert "id" in item
    assert "eventType" in item
    assert "threatType" in item
    assert "riskLevel" in item
    assert "riskScore" in item
    assert "confidence" in item
    assert "reason" in item

def test_get_threat_history_filters():
    # Filter by event_type = sms
    res_sms = client.get("/api/reports/history?event_type=sms")
    assert res_sms.status_code == 200
    data_sms = res_sms.json()
    for item in data_sms["items"]:
        assert item["eventType"] == "sms"

    # Filter by risk_level = high
    res_high = client.get("/api/reports/history?risk_level=high")
    assert res_high.status_code == 200
    data_high = res_high.json()
    for item in data_high["items"]:
        assert item["riskLevel"] == "high"

def test_get_threat_history_invalid_filters():
    res_bad_type = client.get("/api/reports/history?event_type=invalid_vector")
    assert res_bad_type.status_code == 400

    res_bad_level = client.get("/api/reports/history?risk_level=super_critical")
    assert res_bad_level.status_code == 400

def test_get_device_security_score():
    response = client.get("/api/reports/device-score")
    assert response.status_code == 200
    data = response.json()
    assert "score" in data
    assert 0 <= data["score"] <= 100
    assert "grade" in data
    assert "status" in data
    assert "factors" in data
    assert len(data["factors"]) >= 4
    assert "recommendations" in data
    assert data["source"] == "SecureSphere Device Security Engine"

def test_evaluate_device_security_score():
    payload = {
        "metadata": {
            "is_rooted": True,
            "screen_lock_disabled": True,
            "usb_debugging_enabled": True,
        }
    }
    response = client.post("/api/reports/device-score/evaluate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["score"] <= 50  # Should suffer significant penalties
    assert data["status"] in ["Action Recommended", "Vulnerable"]
    assert any(f["factor"] == "Operating System Integrity" and f["status"] == "critical" for f in data["factors"])

def test_get_security_trends():
    response = client.get("/api/reports/trends?days=7")
    assert response.status_code == 200
    data = response.json()
    assert data["days"] == 7
    assert len(data["dataPoints"]) == 7
    assert "categoryDistribution" in data
    assert "riskLevelDistribution" in data
    assert "insights" in data
    assert len(data["insights"]) >= 1

def test_get_security_trends_boundary():
    # Below minimum days (should be rejected by FastAPI Query validation ge=3)
    response_low = client.get("/api/reports/trends?days=2")
    assert response_low.status_code == 422
