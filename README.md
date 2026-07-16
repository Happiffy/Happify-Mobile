# Happify Mobile

Happify Mobile is the Flutter client for mood tracking, journaling, mindfulness, AI companion interactions, professional care, anonymous community support, and Happify Companion devices.

## Overview

The mobile application allows users to:

- Record moods and view wellbeing trends
- Write daily journals and receive optional AI insights
- Use voice sessions with the AI Companion
- Complete breathing, grounding, and mindfulness activities
- Connect and manage a Happify Companion device
- Access anonymous community support, professional referrals, care chat, and emergency contacts

The application does not call Happify AI directly. All application requests are sent to Happify Backend.

## Technology Stack

| Area | Stack |
| --- | --- |
| Framework | Flutter and Dart |
| Navigation | GoRouter |
| State Management | Flutter BLoC and Cubit |
| Networking | Dio |
| Authentication | Firebase Auth |
| Notifications | Firebase Messaging |
| Audio | Record, AudioPlayers, Flutter TTS |
| Local Storage | Shared Preferences and Path Provider |
| UI | Material, Google Fonts, Phosphor Icons, Iconify |
| Testing | Flutter Test |
| Distribution | Android APK and AAB |

## Features

- **Mood Tracker** — Record daily moods and inspect emotional history.
- **Mood Analytics** — Display mood trends and voice-conversation patterns.
- **Daily Journaling** — Save reflections and send them to the backend for optional AI analysis.
- **AI Companion** — Record a voice turn and display transcripts, mood, risk, and response audio.
- **Session Tracking** — Separate distinct companion conversations.
- **Mindfulness** — Breathing, grounding, meditation, and progress tracking.
- **Anonymous Community** — Participate in moderated peer-support interactions.
- **Professional Care** — Request referrals, browse providers, and use care chat.
- **Companion Management** — Pair devices, view telemetry, manage firmware, OTA metadata, and haptic commands.
- **Consent** — Manage consent for AI, voice, device emotion observations, and heatmap contributions.
- **Accessibility** — Text scaling, high contrast, reduced motion, and screen-reader-oriented settings.
- **Firebase Auth and Push** — Sign-in, session restoration, and notification support.

## Application Routes

| Path | Description |
| --- | --- |
| `/` | Splash screen and session restoration |
| `/onboarding` | User onboarding |
| `/welcome` | Welcome screen |
| `/login` | Sign-in |
| `/register` | Registration |
| `/forgot` | Password reset |
| `/consent` | Consent review |
| `/app` | Main Happify shell |
| `/companion` | Companion-device management |
| `/care` | Professional care and care chat |
| `/contacts` | Emergency contacts |
| `/voice` | Voice Companion |

## Environment Variables

Flutter reads configuration through `--dart-define` or `--dart-define-from-file`. Local `.env` files are not committed.

Create `.env` from `.env.example`:

```env
BE_API_URL=http://localhost:4000
```

| Variable | Description |
| --- | --- |
| `BE_API_URL` | Base URL of Happify Backend. |

The mobile client only needs the backend URL. Do not add `AI_SERVICE_BASE_URL` to the mobile application because AI access is brokered by Happify Backend.

## Firebase Configuration

Firebase configuration is not stored in the mobile `.env` file. Use the official platform files:

- Android: `android/app/google-services.json`
- iOS: add `GoogleService-Info.plist` to the Runner target in Xcode

These files are ignored by Git. Without Firebase configuration, the application can still open in guest mode, but authentication and push notifications are unavailable.

## Getting Started

### Prerequisites

- Flutter `3.38.9` stable
- Dart `3.10.8`
- Android Studio or Xcode for the relevant target platform
- A reachable Happify Backend instance
- Firebase project configuration for authentication

### Install Dependencies

```bash
flutter pub get
```

### Android Emulator

Create `.env.emulator`:

```env
BE_API_URL=http://10.0.2.2:4000
```

Run the application:

```bash
flutter run --dart-define-from-file=.env.emulator
```

`10.0.2.2` is the Android emulator alias for the host machine.

### Physical Device

Use a backend URL reachable from the device:

```bash
flutter run --dart-define=BE_API_URL=https://your-backend.example
```

### Local Release Build

```bash
flutter build apk --release --dart-define-from-file=.env
flutter build appbundle --release --dart-define-from-file=.env
```

## Verification

```bash
flutter analyze
flutter build apk --debug --dart-define-from-file=.env
```

## Android Release

Keep the local Android upload keystore at `android/app/happify-upload-key.jks` and its properties in `android/key.properties`. Both files must remain ignored by Git and must be backed up securely.

The Android workflow expects these repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `GOOGLE_SERVICES_JSON_BASE64`

It also supports a `BE_API_URL` configuration variable. The workflow builds signed APK and AAB artifacts through manual dispatch or a `mobile-v*` tag.

## Project Structure

```text
lib
|-- core                 # API client, services, theme, and shared widgets
|-- features
|   |-- auth             # Firebase authentication flow
|   |-- home             # Home shell and dashboard entry
|   |-- mood             # Mood tracking and analytics
|   |-- journal          # Daily journaling
|   |-- companion        # Device pairing and management
|   |-- voice            # AI voice Companion
|   |-- mindfulness      # Mindfulness content and progress
|   |-- community        # Anonymous peer community
|   |-- care             # Professional referrals and care chat
|   |-- consent          # Consent management
|   |-- profile          # Profile and settings
|-- main.dart             # Application entry point and routes
assets
|-- mascot
|-- illustrations
android                    # Android project and release configuration
ios                        # iOS project
```

## Architecture

```text
Happify Mobile
      |
      v
Happify Backend
  |   |   \
  |   |    +--> PostgreSQL-backed API
  |   +-------> Firebase Auth and Messaging
  +-----------> Happify AI through the backend
```
