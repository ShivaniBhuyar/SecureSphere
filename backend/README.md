# SecureSphere Backend API

FastAPI backend providing cybersecurity intelligence, cloud knowledge repository, and AI threat analysis for the SecureSphere Android application.

---

## 1. Quick Start (Local Development)

### Install Requirements
```bash
python -m pip install -r requirements.txt
```

### Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Default `.env` configuration uses SQLite (`sqlite:///./securesphere.db`) for immediate out-of-the-box local testing without requiring PostgreSQL setup.

### Run FastAPI Server
```bash
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
The server will start on `http://0.0.0.0:8000`.
- API Documentation (Swagger UI): `http://localhost:8000/docs`
- Health Check: `http://localhost:8000/api/health`

---

## 2. Testing From a Physical Android Phone

When testing on a real Android device connected via Wi-Fi:
1. Find your computer's local IP address:
   - On Windows: Run `ipconfig` in Command Prompt and find your **IPv4 Address** (e.g. `192.168.1.15`).
2. Ensure the phone and PC are connected to the same Wi-Fi network.
3. Open the SecureSphere app on your phone.
4. The app uses `http://<your-pc-ip>:8000` to reach the FastAPI server. Cleartext HTTP traffic is pre-configured in `AndroidManifest.xml` (`android:usesCleartextTraffic="true"`).

---

## 3. PostgreSQL Database Configuration

For cloud deployment (e.g., AWS RDS, Render, Railway, Google Cloud SQL, Heroku):
Set the `DATABASE_URL` environment variable:
```bash
DATABASE_URL=postgresql://<db_user>:<db_password>@<db_host>:5432/<db_name>
```
On startup, the FastAPI app automatically creates the required tables (`knowledge_entries`, `threat_analysis_logs`) and seeds the verified cyber safety dataset.

---

## 4. External Security Services

Set API keys in `.env` (strictly kept on the server, never exposed to mobile apps):
- `VIRUSTOTAL_API_KEY`: Enables VirusTotal v3 URL threat scans
- `GOOGLE_SAFE_BROWSING_KEY`: Enables Google Safe Browsing v4 reputation checks
- `OPENAI_API_KEY`: Enables conversational and reasoning capabilities

If keys are omitted or external services are unreachable, the backend automatically uses rule-based heuristics and local offline classification without throwing errors.

---

## 5. API Endpoints Reference

### Health
- `GET /api/health`: Returns API availability status (`{"status": "online", "service": "SecureSphere API"}`).

### Cyber Knowledge Base
- `GET /api/knowledge`: List all knowledge topics.
- `GET /api/knowledge/{id}`: Get topic by ID (e.g., `otp_scam`, `upi_scam`).
- `GET /api/knowledge/search?q={query}`: Search topics by keywords or text.
- `GET /api/knowledge/category/{category}`: Filter topics by safety category.

### Threat Detection
- `POST /api/threat/analyze`:
  ```json
  {
    "type": "url",
    "content": "http://suspicious-banking-site.xyz"
  }
  ```
  Returns risk level, score, confidence, indicators, and recommended safe action.
