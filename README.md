# Happify Mobile

Mobile app Happify berbasis Flutter untuk mood tracking, journaling, mindfulness, AI Companion, professional care, dan Companion device.

---

## Overview

Happify Mobile adalah client untuk pengguna yang ingin:

- mencatat mood dan melihat trend kesehatan mental
- menulis daily journal dan mendapatkan insight AI
- berbicara dengan AI Companion melalui voice session
- menjalankan grounding dan mindfulness activities
- menghubungkan aplikasi dengan Happify Companion
- mengakses community, care referral, dan emergency contact

Mobile app tidak memanggil AI-Happify secara langsung. Semua request aplikasi dikirim ke BE-Happify.

---

## Tech Stack

| Area | Stack |
| --- | --- |
| Framework | Flutter, Dart |
| Navigation | GoRouter |
| State Management | Flutter BLoC / Cubit |
| Networking | Dio |
| Authentication | Firebase Auth |
| Push Notification | Firebase Messaging |
| Audio | Record, AudioPlayers, Flutter TTS |
| Storage | Shared Preferences, Path Provider |
| UI | Material, Google Fonts, Phosphor Icons, Flutter Animate |
| Testing | Flutter Test, Bloc Test |
| Distribution | Android APK / AAB |

---

## Features

- **Mood Tracker** - catat mood harian dan lihat histori perubahan emosi.
- **Mood Analytics** - tampilkan trend mood serta pola hasil voice conversation.
- **Daily Journaling** - tulis refleksi harian dan kirim ke backend untuk optional AI analysis.
- **AI Companion** - rekam percakapan, kirim voice turn, tampilkan transcript, mood, risk, dan response audio.
- **Session Tracking** - gunakan sesi baru untuk memisahkan percakapan curhat.
- **Mindfulness** - breathing, grounding, meditation, dan progress tracking.
- **Community** - akses peer support dan moderated community.
- **Professional Care** - referral ke psikolog, provider, dan care chat.
- **Companion Management** - pairing device, telemetry, firmware, OTA, dan haptic command.
- **Consent** - consent untuk AI, voice, device emotion observation, dan heatmap.
- **Accessibility** - text scale, high contrast, reduced motion, dan screen-reader support.
- **Firebase Auth and Push** - login, session restore, dan notification support.

---

## App Routes

| Path | Description |
| --- | --- |
| `/` | Splash dan session restore |
| `/onboarding` | Onboarding pengguna |
| `/welcome` | Welcome page |
| `/login` | Login |
| `/register` | Registrasi |
| `/forgot` | Forgot password |
| `/consent` | Consent review |
| `/app` | Main Happify shell |
| `/companion` | Companion device management |
| `/care` | Professional care dan care chat |
| `/contacts` | Emergency contacts |
| `/voice` | Voice Companion |

---

## Environment Variables

Flutter membaca environment melalui `--dart-define-from-file`. File `.env` lokal tidak di-commit.

Buat `.env` dari `.env.example`:

```env
BE_API_URL=https://happify-be-production.up.railway.app
```

| Variable | Description |
| --- | --- |
| `BE_API_URL` | Base URL BE-Happify. Production: `https://happify-be-production.up.railway.app`. |

Mobile hanya membutuhkan URL backend. Jangan masukkan `AI_SERVICE_BASE_URL` ke mobile karena AI hanya diakses oleh BE-Happify.

---

## Firebase Configuration

Firebase tidak dimasukkan ke `.env` mobile. Gunakan file native resmi:

- Android: `android/app/google-services.json`
- iOS: tambahkan `GoogleService-Info.plist` ke Runner target di Xcode

Tanpa file Firebase, app tetap dapat dibuka dalam guest mode, tetapi authentication dan push notification tidak aktif.

---

## Getting Started

### Prerequisites

- Flutter `3.38.9` stable
- Dart `3.10.8`
- Android Studio atau Xcode sesuai platform
- BE-Happify berjalan atau URL production yang dapat dijangkau
- Firebase project configuration untuk authentication

### Installation

```bash
flutter pub get
```

### Android Emulator

Buat atau gunakan `.env.emulator`:

```env
BE_API_URL=http://10.0.2.2:4000
```

Run:

```bash
flutter run --dart-define-from-file=.env.emulator
```

`10.0.2.2` adalah alamat host machine dari Android emulator.

### Physical Device

Gunakan URL backend yang dapat dijangkau device, biasanya HTTPS:

```bash
flutter run --dart-define=BE_API_URL=https://happify-be-production.up.railway.app
```

### Production Local Build

```bash
flutter build apk --release --dart-define-from-file=.env
flutter build appbundle --release --dart-define-from-file=.env
```

---

## Verification

```bash
flutter analyze
flutter test
```

---

## Android Release

Upload keystore lokal berada di `android/app/happify-upload-key.jks` dan credential berada di `android/key.properties`. Keduanya harus tetap ignored dan dibackup secara aman.

Jika `MOBILE-Happify` dipush sebagai repository GitHub sendiri, GitHub Actions menggunakan environment `mobile-release` dengan:

### Variable

- `BE_API_URL`

### Secrets

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `GOOGLE_SERVICES_JSON_BASE64`

Workflow release membuat signed APK dan AAB melalui manual dispatch atau tag `mobile-v*`.

---

## Deployment URLs

| Service | URL |
| --- | --- |
| Production Backend | `https://happify-be-production.up.railway.app` |
| AI Service | `https://happify-ai-production.up.railway.app` |

Mobile hanya menggunakan URL Production Backend. AI Service URL tidak dimasukkan ke mobile.

---

## Project Structure

```txt
lib
|-- core                 # API client, services, theme, shared widgets
|-- features
|   |-- auth              # Firebase auth flow
|   |-- home              # Home shell dan dashboard entry
|   |-- mood              # Mood tracker dan mood analytics
|   |-- journal           # Daily journaling
|   |-- companion         # Device pairing dan management
|   |-- voice             # AI voice Companion
|   |-- mindfulness       # Mindfulness content dan progress
|   |-- community         # Peer community
|   |-- care              # Professional referral dan care chat
|   |-- consent           # Consent management
|   |-- profile           # Profile dan settings
|-- main.dart             # App entry point dan route configuration
assets
|-- mascot
|-- illustrations
|-- animations
android                    # Android project dan release configuration
ios                       # iOS project
```

---

## Architecture

```text
Happify Mobile
      |
      v
BE-Happify
  |   |   \
  |   |    +--> PostgreSQL-backed API
  |   +-------> Firebase Auth / Messaging
  +-----------> AI-Happify through backend
```
