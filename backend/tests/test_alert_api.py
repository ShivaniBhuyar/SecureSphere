import os
import sys
import uuid
import pytest
from fastapi.testclient import TestClient

# Ensure backend directory is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from app.main import app
from app.database import Base, engine, SessionLocal

from app.models.alert import AlertModel

client = TestClient(app)

def setup_module():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        db.query(AlertModel).delete()
        db.commit()
    finally:
        db.close()

def test_create_alert_success():
    payload = {
        "threatId": str(uuid.uuid4()),
        "threatType": "sms_threat",
        "riskLevel": "high",
        "riskScore": 88,
        "confidence": 0.95,
        "title": "URGENT: Banking Smishing Detected",
        "reason": "Suspicious SMS demanding OTP for account unlock.",
        "indicators": [
            "Demands 6-digit OTP",
            "Urgent threat of account suspension",
            "Unverified external link: bit.ly/fake-bank"
        ],
        "recommendedAction": "Do not reply or share your OTP. Block the sender.",
        "relatedKnowledgeEntries": [
            {"id": "sms_phishing", "title": "SMS Phishing (Smishing)"}
        ],
        "metadata": {"sender": "+919876543210"}
    }

    response = client.post("/api/alerts", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["threatType"] == "sms_threat"
    assert data["riskLevel"] == "high"
    assert data["riskScore"] == 88
    assert data["confidence"] == 0.95
    assert data["isRead"] is False
    assert len(data["indicators"]) == 3
    assert "bit.ly/fake-bank" in data["indicators"][2]
    assert len(data["relatedKnowledgeEntries"]) == 1

def test_duplicate_alert_prevention():
    same_threat_id = str(uuid.uuid4())
    payload = {
        "threatId": same_threat_id,
        "threatType": "url_threat",
        "riskLevel": "high",
        "riskScore": 92,
        "confidence": 0.99,
        "title": "Malicious Phishing Portal",
        "reason": "Known credential harvesting site hosted on dynamic DNS.",
        "indicators": ["Deceptive domain name", "Requests banking credentials"],
        "recommendedAction": "Close the page immediately."
    }

    # First creation
    res1 = client.post("/api/alerts", json=payload)
    assert res1.status_code == 201
    alert_1 = res1.json()

    # Second creation with identical threatId (deduplication check)
    res2 = client.post("/api/alerts", json=payload)
    assert res2.status_code == 201
    alert_2 = res2.json()

    # Both responses must refer to the exact same alert ID!
    assert alert_1["id"] == alert_2["id"]

def test_get_alerts_and_unread_count():
    # Fetch all alerts
    response = client.get("/api/alerts")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "unreadCount" in data
    assert "items" in data
    assert data["total"] >= 1
    assert data["unreadCount"] >= 1

    # Fetch unread count endpoint
    unread_res = client.get("/api/alerts/unread-count")
    assert unread_res.status_code == 200
    assert "unreadCount" in unread_res.json()
    assert unread_res.json()["unreadCount"] == data["unreadCount"]

def test_mark_alert_as_read():
    # Create a fresh alert
    payload = {
        "threatId": str(uuid.uuid4()),
        "threatType": "device_threat",
        "riskLevel": "medium",
        "riskScore": 55,
        "confidence": 0.85,
        "title": "Developer Options Enabled",
        "reason": f"Developer Options and USB Debugging active: {uuid.uuid4()}",
        "indicators": ["USB debugging enabled"],
        "recommendedAction": "Disable Developer Options in Device Settings."
    }
    res = client.post("/api/alerts", json=payload)
    assert res.status_code == 201
    alert = res.json()
    alert_id = alert["id"]
    assert alert["isRead"] is False

    # Mark as read
    patch_res = client.patch(f"/api/alerts/{alert_id}/read")
    assert patch_res.status_code == 200
    updated = patch_res.json()
    assert updated["id"] == alert_id
    assert updated["isRead"] is True

    # Check that it reflects in get_alerts
    get_res = client.get("/api/alerts")
    matching = [a for a in get_res.json()["items"] if a["id"] == alert_id]
    assert len(matching) == 1
    assert matching[0]["isRead"] is True

def test_mark_all_alerts_read():
    # Mark all read
    post_res = client.post("/api/alerts/mark-all-read")
    assert post_res.status_code == 200
    data = post_res.json()
    assert data["success"] is True

    # Unread count should now be 0
    unread_res = client.get("/api/alerts/unread-count")
    assert unread_res.json()["unreadCount"] == 0

def test_invalid_alert_payload():
    # Missing required reason
    payload = {
        "threatType": "sms_threat",
        "reason": ""
    }
    res = client.post("/api/alerts", json=payload)
    assert res.status_code in [400, 422]

def test_mark_nonexistent_alert_read():
    fake_id = "non-existent-alert-id-999"
    res = client.patch(f"/api/alerts/{fake_id}/read")
    assert res.status_code == 404
