# Aurora – Mental Health Companion App

> Course: **CSCI4100U Mobile Devices – Ontario Tech University**

**Aurora** (project codename "Aurora" in this repository) is a mobile application concept that supports student mental health and overall wellness in a demanding academic environment. The long‑term vision includes:

* Tracking emotions and mood trends
* Secure journaling of thoughts
* Guided breathing, brief meditations, mindfulness tasks
* Data‑driven insights that encourage healthy coping strategies

From a user perspective, Aurora aims to feel like a personal companion—available to offer support, monitor progress, and encourage resilience and self‑awareness. Ultimately, it intends to provide a wellness platform fostering mental equilibrium rather than just productivity.

### Current Implementation (Truthful Status)
The present prototype focuses on the **foundational platform pieces** only (authentication, secure user profile storage, UI scaffolding). The wellness tracking, journaling, breathing/meditation, and analytics features described above are **not yet implemented** and remain future scope.

Aurora (current code) delivers:
* Firebase initialization and configuration
* Email/password signup & login flows
* Password reset via Firebase Auth templated email
* Reactive auth state gate routing between landing and dashboard
* User profile document creation & merge updates in Firestore (display name, birthday, height, weight)
* Settings screen allowing profile edits with validation and age calculation
* Consistent themed UI components (custom text fields, auth buttons, password strength meter)

## Project Status
Early prototype: core authentication, user profile storage, and primary UI flows (landing, signup, login, password reset, dashboard, settings/profile editing) implemented. Journaling, mood tracking, breathing exercises, meditation, mindfulness tasks, and analytics are planned but not yet built.

## Major Technical Contributions

### Contributor: Sunny Patel (100867748)

Sunny has implemented the foundational infrastructure portions of the application, including Firebase initialization, authentication flows, user data modeling, secure profile updates, and the custom UI components for auth and onboarding. For the Journals feature, Sunny connected it to Firestore using per‑user (UID) paths and a nested collection /users/journalEntries/{...hash}; implemented the data aggregation/streaming logic.

| Area | Description of Contribution | Key Files / Code | Notes |
|------|-----------------------------|------------------|-------|
| Project Bootstrapping | Initialized Flutter project structure, configured Material 3 theme, seeded color palette, disabled debug banner. | `lib/main.dart` (`AuroraApp`, theme setup) | Established consistent look and feel. |
| Firebase Initialization | Integrated Firebase using generated `firebase_options.dart`, ensured `WidgetsFlutterBinding.ensureInitialized()` and platform options usage before runApp. | `lib/main.dart`, `lib/firebase_options.dart` | Required for all backend services. |
| Auth State Gate | Implemented reactive auth gate with `StreamBuilder` switching between `DashboardScreen` and `LandingScreen` based on `AuthService.instance.authStateChanges()`. | `lib/main.dart` (`_AuthGate`) | Central routing logic after splash/loading. |
| Authentication Service | Designed a robust `AuthService` singleton wrapping FirebaseAuth and Firestore profile creation/updates (signUp, signIn, signOut, updateProfile, password reset, unified error mapping). Uses proper `rethrow` to preserve stack traces. | `lib/services/auth_service.dart` | Provides abstraction isolating Firebase specifics from UI. |
| User Profile Persistence | Automatic creation/merge of user document on signup; structured fields (`displayName`, `fullName`, timestamps). Profile updates with merge semantics, timestamping, optional fields for birthday, height, weight. | `lib/services/auth_service.dart` (`signUp`, `updateProfile`) | Ensures extensible schema with minimal writes. |
| Error Handling & Mapping | Centralized conversion of Firebase & platform exceptions to user-friendly messages through `mapAuthError`. | `lib/services/auth_service.dart` | Promotes consistent UX for failures. |
| Landing Experience | Crafted a minimalist landing screen with custom glowing candle widget, thematic color palette, and navigation into login flow. | `lib/screens/landing_screen.dart` | Establishes brand identity and calm aesthetic. |
| Login Flow | Built email/password login with validation, loading states, toast/snackbar feedback, and password reset initiation integrated with Firebase (`sendPasswordResetEmail`). | `lib/screens/auth/login_screen.dart` | Enhances usability with inline error messages and state management. |
| Password Reset | Implemented client-side validation, asynchronous reset request, and user feedback via SnackBar; triggers Firebase templated email. | `lib/screens/auth/login_screen.dart` (`_handleResetPassword`) | Enables account recovery securely. ![](README_SCREENSHOTS\pwd_reset_auth_email.png) |
| Signup Flow | Implemented multi-field registration (name, email, password, confirm) with strong validation rules and a live password strength meter (length, uppercase, special char, extended length bonus). | `lib/screens/auth/signup_screen.dart` | Improves password hygiene and reduces weak passwords. |
| Custom Password Strength Component | Designed `_PasswordStrengthBar` to visually communicate strength with adaptive color palette and explanatory messaging. | `lib/screens/auth/signup_screen.dart` | Encourages secure credential creation. |
| Reusable Form Components | Created `CustomTextField` abstraction with consistent styling, focus/validation borders, suffix icons for password visibility toggling. | `lib/widgets/auth/custom_text_field.dart` | Streamlines future form creation and reduces duplication. |
| Reusable Action Button | Implemented `AuthButton` with loading state, disabled styling, and accessible sizing standards. | `lib/widgets/auth/auth_button.dart` | Uniform CTA styling across auth flows. |
| Dashboard Welcome | Added dynamic welcome messaging resolving best display name from Firestore or auth profile; integrated live Firestore stream for real-time profile reflection. | `lib/screens/dashboard_screen.dart` | Demonstrates reactive data binding. |
| Settings & Profile Editing | Built form-driven settings page to update display name, birthday (with date picker & age calc), height, weight; included validation, feedback, and Firestore merge update logic. | `lib/screens/settings_screen.dart`, `AuthService.updateProfile` | Provides foundation for future wellness metrics. |
| Date & Age Utilities | Implemented parsing/formatting helpers and age calculation logic to enhance profile semantics. | `lib/screens/settings_screen.dart` | Prepares app for age-relevant features. |
| UI/UX Consistency | Applied cohesive color scheme (#F5C97B seeds, soft neutrals), elevation, spacing standards, and typography hierarchy across all screens. | Multiple UI files | Ensures calm, coherent user experience. |
| Code Quality & Lints | Addressed Dart analyzer suggestions (e.g., replacing `throw e` with `rethrow` for stack preservation). | `lib/services/auth_service.dart` | Maintains clean analyzer output (0 issues). |
| CI Workflow | Added GitHub Actions workflow running `flutter pub get` and `flutter analyze` on pushes/PRs to `main` ensuring static analysis passes before merge. | `.github/workflows/flutter-ci.yml` | Automates quality checks. |
| Unified Snackbar System | Implemented custom overlay-based Aurora snackbar/toast with semantic variants (success, error, info, alert) replacing platform default dark bar, ensuring accessible calm styling. | `lib/widgets/aurora_snackbar.dart`, variant usage across screens | Consistent UX feedback surface (icons, color accents, animation). |
| Notification & Reminder System | Expanded notification service: timezone init, permission requests (Android/iOS/macOS), Android channel creation, persistent daily journal reminder scheduling, instant & one-off notifications, tap payload handler. Integrated auto scheduling at app start and after successful journal save. | `lib/services/notifications_service.dart`, `lib/main.dart`, `lib/screens/journal_screen.dart` | Foundation for future wellness nudges & behavioral habit formation. |
| Min SDK Update | Adjusted Android `minSdk` to 23 for Firebase Auth compatibility; enabled predictive back callback for Android 13+. | `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml` | Resolves build error & improves navigation UX. |
| HTTP Remote Quote Fetch | `RemoteResourceService` now uses RealInspire public endpoint (no key, CORS safe) to load a random encouragement quote with fallback list & refresh UI. | `lib/services/remote_resource_service.dart`, `lib/screens/resources.dart` | External API consumption & resilient network handling. |

## Running the App

```bash
flutter pub get
flutter analyze
flutter run
```

Ensure a valid `google-services.json` (Android) and Firebase configuration are present; `firebase_options.dart` was generated via FlutterFire CLI.

## Tech Stack
- Flutter (Material 3, custom theming)
- Firebase Auth & Cloud Firestore
- Dart Streams & reactive UI