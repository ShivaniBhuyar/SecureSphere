# SecureSphere 🛡️

**SecureSphere** is a modern, privacy-first cybersecurity guardian mobile application built with **Flutter** and backed by a high-performance **FastAPI** backend service. It delivers proactive digital threat detection, real-time safety monitoring, an interactive cybersecurity knowledge hub, and an AI-driven digital safety companion.

---

## 🚀 Completed Modules (Modules 1–4)

### 🔹 Module 1: Project Foundation & Core Architecture
- **Material 3 Design System**: Custom security-themed UI with Dark and Light mode support, dynamic risk palettes, and smooth animations.
- **Responsive Layout & Navigation**: Persistent bottom navigation layout featuring Home, Safety Guard, AI Assistant, Alerts, and Profile views.
- **Profile & Preferences**: Local state persistence with `shared_preferences` and permission handling.

### 🔹 Module 2: Security Dashboard & Real-Time Monitoring
- **Guardian Status Hero**: Real-time visual indicator of device safety status and active protection level.
- **Monitoring Service**: Event queue tracking simulated device security signals, app installations, and permission changes.
- **Interactive Security Cards**: Quick-action safety tips, threat summary cards, and recent activity timelines.

### 🔹 Module 3: Threat Detection & Analysis Engine
- **Multi-Vector Scanning**: Evaluates suspicious SMS messages, phishing emails, unknown sender text, and malicious URLs.
- **Hybrid Intelligence**:
  - On-device heuristic analysis via `LocalThreatAnalyzer`.
  - Cloud-powered deep inspection via FastAPI `/api/threat/analyze`.
- **Actionable Risk Breakdown**: Detailed threat score (0–100), severity categorization (*Safe*, *Low*, *Medium*, *High*, *Critical*), threat indicators, and defensive remediation recommendations.

### 🔹 Module 4: Cyber Safety Knowledge Hub & AI Companion
- **Cyber Safety Knowledge Base**: Categorized library of online fraud defense (OTP safety, UPI payment scams, KYC fraud, password best practices, public Wi-Fi security).
- **Search & Filter**: Keyword indexing and category filters with instant response and offline fallback support.
- **Ask SecureSphere**: AI safety chat assistant providing conversational answers to cyber threats and fraud inquiries.

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

## 🗺️ Roadmap (Upcoming Modules)
- **Module 5**: Automated On-Device App Permission Audit & Privacy Scorecard
- **Module 6**: Background SMS & Notification Listener with Proactive Fraud Alerts
- **Module 7**: End-to-End Encrypted Community Threat Intelligence Reporting

