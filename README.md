<div align="center">

# Aurora ✨

Mental wellness & personal growth companion built with Flutter & Firebase.

[![License](https://img.shields.io/github/license/sunnypatell/csci4100u-aurora?style=flat-square)](LICENSE)
[![Issues](https://img.shields.io/github/issues/sunnypatell/csci4100u-aurora?style=flat-square)](https://github.com/sunnypatell/csci4100u-aurora/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/sunnypatell/csci4100u-aurora?style=flat-square)](https://github.com/sunnypatell/csci4100u-aurora/pulls)
[![Last Commit](https://img.shields.io/github/last-commit/sunnypatell/csci4100u-aurora?style=flat-square)](https://github.com/sunnypatell/csci4100u-aurora/commits/main)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter&style=flat-square)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Active-orange?logo=firebase&style=flat-square)](https://firebase.google.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](#-contributing)

</div>

## Overview
Aurora is a cross‑platform (Android, iOS, Web) Flutter application focused on mental health support, habit reflection, and contextual help resources. It integrates journaling, timeline tracking, resource discovery, chat, and proximity-based assistance features; powered by Firebase services.

> This project is a CSCI 4100U course group submission. While it aims for production quality structure, it remains an active academic build. Suggestions & improvements are welcome.

## Key Features
- Secure authentication & session handling (Firebase Auth)
- Personal journal entries with persistence (Cloud Firestore)
- Chat interface (planned real‑time messaging)
- Resource hub (curated wellness + support materials)
- "Help Near Me" location-aware assistance (design stage)
- Dashboard & timeline visualizations for progress tracking
- Push notifications (Firebase Cloud Messaging)
- Multi‑platform Flutter build pipeline
- Remote motivational quote via HTTP (RealInspire API) in Resources

## Tech Stack
- **Framework:** Flutter (Dart)
- **Backend Services:** Firebase (Auth, Firestore, Cloud Messaging, Analytics)
- **CI/CD:** (Planned GitHub Actions workflow)
- **Platforms Targeted:** Android, iOS, Web, Windows, macOS, Linux

## Project Structure (High-Level)
```
aurora_app/
	lib/
		screens/        # UI screens (dashboard, journal, chat, etc.)
		services/       # Abstracted app logic (auth, journal, notifications)
		widgets/        # Reusable presentation components
		firebase_options.dart  # Generated Firebase config
	assets/           # Images & static assets
	android/ios/...   # Platform-specific Flutter scaffolding
	test/             # Widget & unit tests
```

## Screens (Implemented / In Progress)
- `landing_screen.dart` – Entry & onboarding flow
- `home_screen.dart` – Main navigation hub
- `dashboard_screen.dart` – Overview metrics & summaries
- `journal_screen.dart` – Create & browse personal entries
- `timeline_tab.dart` – Chronological reflection / activity stream
- `chat.dart` – Placeholder for real‑time messaging (integration pending)
- `help_near_me.dart` – Contextual nearby support (prototype phase)
- `resources.dart` – Curated resource listing
- `settings_screen.dart` – Profile & app preferences

## Group Members
| Name |
|------|
| Sunny Patel |
| Sanhith Amarathunge |
| Aakanksha Parekh |
| Paul Joseph |
| Suthashan Tharmarajah |

## Quick Start (Windows PowerShell)
```powershell
git clone https://github.com/sunnypatell/csci4100u-aurora.git
cd csci4100u-aurora/aurora_app
flutter pub get
flutter run
```
## Gemini AI Key Setup

Aurora's AI features (journal insight, contextual chat, conversation title generation) require a Gemini API key loaded from an environment file.

Setup via CLI (Windows PowerShell):
```powershell
cd aurora_app
cp .env.example .env
```
Then open the `.env` file in your editor and replace `YOUR_KEY_HERE` with your real Gemini API key. Save the file before running.

Run the app:
```powershell
flutter pub get
flutter run
```

For Web builds if you decide to run on chrome, pass the key via dart-define:
```powershell
cd aurora_app
flutter pub get
flutter run -d chrome --dart-define=GEMINI_API_KEY=<YOUR_KEY_HERE>
```
Your final command for web should look like:
```powershell
flutter run -d chrome --dart-define=GEMINI_API_KEY=abracadabra_blah.blah.blah.12345.
```


If the key is missing, AI responses will return a friendly message indicating configuration is needed.

Security notes:
- The `.env` file is gitignored; do not commit real keys.
- Rotate keys immediately if leaked.
- For production, prefer a backend proxy or secure secret manager.


### Prerequisites
- Install Flutter SDK (`>=3.x`).
- Ensure Dart is bundled (with Flutter install).
- Node.js for Firebase CLI.
- A Firebase project with enabled Auth + Firestore + Messaging.

### Firebase Configuration
1. Create a Firebase project in the Firebase console.
2. Enable **Email/Password** (and other desired) authentication providers.
3. Create Firestore DB in production or test mode per requirements.
4. (Optional) Set up Cloud Messaging for push notifications.
5. Run `flutterfire configure` from `aurora_app/` to generate `lib/firebase_options.dart`.
6. Add platform configs (`google-services.json`, `GoogleService-Info.plist`) already present / update as needed.

## Development Scripts (Suggested)
| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies |
| `flutter analyze` | Static analysis (lint) |
| `flutter test` | Run test suite |
| `flutter run -d chrome` | Launch web build |
| `flutter build apk` | Produce Android release artifact |

## Testing
Run widget tests:
```powershell
flutter test
```
Add more tests under `test/` for services & UI states (e.g., authentication flows, journal CRUD, notification triggers).

## Roadmap
- Integrate real‑time chat (Firestore listener / WebSockets alternative)
- Add mood tracking & analytics dashboard
- Implement offline sync layer
- Role-based resource personalization
- CI workflow (GitHub Actions) for build + analyze + test
- Accessibility audit (contrast, semantic widgets)
- Internationalization (i18n) scaffolding

## Contributing
We welcome thoughtful contributions. For external contributors (post-course):
1. Fork the repo.
2. Create feature branch: `git checkout -b feature/your-feature`.
3. Commit with conventional messages (e.g., `feat: add journal filtering`).
4. Run `flutter analyze` & `flutter test` before PR.
5. Open Pull Request with description & screenshots if UI related.

### Code Style
- Follow Dart & Flutter best practices.
- Keep widgets small & composable.
- Avoid logic in UI layer; prefer `services/` abstractions.

## Security & Privacy
- Do not commit secrets or service account keys.
- Use environment-based Firebase project separation for staging vs production.
- Sanitize any user-generated content displayed publicly.

## Troubleshooting
| Issue | Possible Fix |
|-------|--------------|
| Firebase auth fails | Re-run `flutterfire configure`; check API keys |
| Assets not loading | Run `flutter pub get`; verify `pubspec.yaml` assets section |
| iOS build errors | Open Xcode, run pod install in `ios/` if needed |
| Web blank screen | Clear cache; run with `flutter run -d chrome --web-renderer html` |
| Android gradle sync | Delete `.gradle/` then `flutter clean` & retry |

## License
Distributed under the terms of the MIT License. See [`LICENSE`](LICENSE) for details.

## Acknowledgements
- Flutter & Firebase teams for tooling.
- Open source mental health initiative inspirations.
- Course faculty for project guidance.

---
Made with curiosity, care, and Flutter 💙

## Feature Matrix
| Feature | Status | Notes |
|---------|--------|-------|
| HTTP Remote Quote (ZenQuotes) | ✅ Implemented | Fetch & refresh daily encouragement card in `resources.dart` |
