# SecureSphere 🛡️

**SecureSphere** is a modern, privacy-first cybersecurity guardian mobile application built with **Flutter** and backed by a high-performance **FastAPI** backend service. It delivers proactive digital threat detection, real-time safety monitoring, an interactive cybersecurity knowledge hub, and an AI-driven digital safety companion.

---

## 📊 Module Progress

### Project Modules

#### Module 1 — User Interface
Status: ✅ Complete

#### Module 2 — Background Monitoring
Status: ✅ Complete

#### Module 3 — AI Threat Detection
Status: ✅ Complete

#### Module 4 — Cyber Knowledge Base
Status: ✅ Complete

#### Module 5 — Alert & Notification
Status: ✅ Complete
- Implemented
- Tested
- Committed
- Pushed to GitHub
- Deployed to Render
- Live API verified successfully
- Commit: `b0c88a08ca05da32d403ff97c58c31380fa83522`

#### Module 6 — AI Chatbot
Status: ✅ Complete
- Implemented
- Tested
- Committed
- Pushed to GitHub
- Deployed to Render
- Live API verified successfully
- Commit: `1cbeb27`

#### Module 7 — Reports & Analytics
Status: ✅ Complete
- Implemented
- Tested
- Committed
- Commit: `64a0ff5`

---

## 🚀 Completed Modules (Modules 1–7)

### 🔹 Module 1: User Interface
- **Material 3 Design System**: Custom security-themed UI with Dark and Light mode support, dynamic risk palettes, and smooth animations.
- **Responsive Layout & Navigation**: Persistent 5-tab bottom navigation layout featuring Home, Safety Guard, AI Assistant, Alerts, and Profile views.
- **Profile & Preferences**:
  - **Privacy Information**: Direct access to privacy principles, local-first processing information, and permission explanations via `PermissionsScreen`.
  - **Notification Preference Control**: User toggle for in-app floating security alert banners managed by `NotificationService`.
  - **Voice Assistance Access**: Convenient navigation and guidance to AI Assistant microphone speech input and text-to-speech audio reader.
  - **Security Reports Access**: Quick navigation entry point to comprehensive security reports and device score.

### 🔹 Module 2: Background Monitoring
- **Guardian Status Hero**: Real-time visual indicator of device safety status and active protection level.
- **Monitoring Service**: Event queue tracking simulated device security signals, app installations, and permission changes.
- **Interactive Security Cards**: Quick-action safety tips, threat summary cards, and recent activity timelines.

### 🔹 Module 3: AI Threat Detection
- **Multi-Vector Scanning**: Evaluates suspicious SMS messages, phishing emails, unknown sender text, and malicious URLs.
- **Hybrid Intelligence**:
  - On-device heuristic analysis via `LocalThreatAnalyzer`.
  - Cloud-powered deep inspection via FastAPI `/api/threat/analyze`.
- **Actionable Risk Breakdown**: Detailed threat score (0–100), severity categorization (*Safe*, *Low*, *Medium*, *High*, *Critical*), threat indicators, and defensive remediation recommendations.

### 🔹 Module 4: Cyber Knowledge Base
- **Cyber Safety Knowledge Base**: Categorized library of online fraud defense (OTP safety, UPI payment scams, KYC fraud, password best practices, public Wi-Fi security).
- **Search & Filter**: Keyword indexing and category filters with instant response and offline fallback support.
- **Threat Education Hub**: Structured playbooks and proactive educational resources for emerging cyber threats.

### 🔹 Module 5: Alert & Notification
- **Alert & Notification System**: Comprehensive security alert management, in-app security alert banner delivery, and incident tracking across client and backend.
- **Live Cloud Deployment**: Fully deployed to Render with live API endpoints operational and verified.
- **Verification Details**:
  - Implemented
  - Tested
  - Committed
  - Pushed to GitHub
  - Deployed to Render
  - Live API verified successfully
  - **Commit**: `b0c88a08ca05da32d403ff97c58c31380fa83522`

### 🔹 Module 6: AI Chatbot
- **Conversational AI Guardian**: 24/7 cybersecurity incident guidance, fraud defense explanations, and real-time incident playbooks powered by FastAPI `/api/chatbot/message`.
- **Knowledge Base & Alert Correlation**: Dynamic context linking to cybersecurity knowledge entries and device security alerts.
- **Speech & Audio Support**: Speech-to-text voice query input and text-to-speech response playback.
- **Incident Playbooks**: Step-by-step mitigation guidance for OTP fraud, UPI scam recovery, malicious app response, and phishing avoidance.
- **Commit**: `1cbeb27`

### 🔹 Module 7: Reports & Analytics
- **Threat History**:
  - Historical threat analysis records from device events and manual scans.
  - Newest-first chronology with threat-type and severity filtering.
  - Threat detail viewing with actionable remediation history and offline persistence.
- **Security Reports**:
  - Comprehensive security overview and overall security posture (*Protected*, *Warning*, *At Risk*).
  - Activity statistics, threat metrics, and scan volume summaries.
  - Exportable plain-text security digest for user incident records.
- **Device Security Score**:
  - Evaluated 0–100 security rating gauge based on threat frequency, severity, and defense engagement.
  - Multi-factor evaluation: Incident History, Protection Status, Permissions, and Knowledge Base engagement.
  - Risk visualization and prioritized security recommendations to improve device posture.
- **Trends & Insights**:
  - Multi-period scan and threat trends (7-day, 30-day, all-time).
  - Threat severity distribution and data-driven security insights.
- **Backend Reports APIs**:
  - `GET /api/reports/summary`: Security overview and threat statistics.
  - `GET /api/reports/history`: Paginated threat log history with type and level filters.
  - `GET /api/reports/device-score`: Current device security score evaluation with factor breakdowns.
  - `GET /api/reports/trends`: Chronological trend data points.
- **Commit**: `64a0ff5`

---

## 🏗️ Project Architecture

```
Securespher_Android1/
├── android/                 # Android native project files
├── assets/images/           # UI graphics, shields, and category illustrations
├── backend/                 # FastAPI backend server
│   ├── app/                 # FastAPI routes, models, schemas, and services
│   ├── tests/               # Pytest suite for backend APIs
│   ├── Dockerfile           # Containerized deployment spec
│   ├── Procfile             # Process manager configuration
│   ├── render.yaml          # Cloud deployment blueprint
│   ├── requirements.txt     # Python dependencies
│   └── .env.example         # Template for backend secrets & settings
├── ios/                     # iOS native project files
├── lib/                     # Flutter cross-platform source code
│   ├── config/              # Centralized API and environment configuration
│   ├── models/              # Threat, knowledge, event, and user models
│   ├── screens/             # UI screens (Home, Threat Detection, Knowledge, etc.)
│   ├── services/            # API client, threat analyzers, monitoring services
│   ├── theme/               # Colors, typography, and styling
│   └── widgets/             # Reusable UI components and cards
├── test/                    # Flutter unit & widget tests
└── pubspec.yaml             # Flutter dependencies and assets
```

---

## ⚙️ Getting Started

### 1. Prerequisites
- **Flutter SDK**: `>= 3.44.0` (Dart SDK `>= 3.12.0`)
- **Python**: `>= 3.10`
- **Android Studio** / **VS Code** with Flutter extensions
- Physical Android device or Android Emulator

### 2. Backend Setup
```bash
# Navigate to backend directory
cd backend

# Install Python dependencies
pip install -r requirements.txt

# Create environment configuration
copy .env.example .env

# Run FastAPI development server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- API Documentation (Swagger UI): `http://127.0.0.1:8000/docs`
- Health check: `http://127.0.0.1:8000/api/health`

### 3. Running Flutter on Physical Android Device
When testing on a connected Android phone over USB:
```bash
# Forward phone port 8000 to computer port 8000
adb reverse tcp:8000 tcp:8000

# Install dependencies
flutter pub get

# Run on connected device with local API endpoint
flutter run -d <device_id> --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### 4. Running Test Suites
```bash
# Run Flutter tests
flutter test

# Run Backend tests
pytest backend/tests/
```

---

## 🔒 Security & Privacy Notice
- **Zero Exposed Keys**: All external threat intelligence credentials (VirusTotal, Google Safe Browsing, etc.) are strictly isolated on the backend server.
- **Environment Isolation**: `.env`, databases (`*.db`), signing keystores, and build artifacts are strictly excluded via `.gitignore`.
- **Local Fallback**: The Flutter application is built with complete offline resilience, gracefully falling back to local heuristic engines whenever cloud services are unreachable.

---

## 🗺️ Roadmap & Project Status
- **Modules 1–7 Completed**: All core modules outlined in the official SecureSphere architecture (UI, Background Monitoring, AI Threat Detection, Cyber Knowledge Base, Alert & Notification, AI Chatbot, and Reports & Analytics) are implemented, verified, and operational.

