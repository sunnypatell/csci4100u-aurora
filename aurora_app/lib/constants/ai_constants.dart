// ai_constants.dart
// Centralized constants & env-driven configuration for Gemini integration.
//
// SECURITY NOTE:
// - The API key is now loaded at runtime from `.env` (gitignored) using
//   flutter_dotenv. Ensure you create a `.env` by copying `.env.example`.
// - Never commit real API keys. If a key is accidentally leaked, rotate it
//   immediately in the provider dashboard.
// - For production, prefer a backend proxy or a secure secret manager over
//   embedding client-side keys.
//
// This file stays intentionally minimal.

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiConstants {
    static const String geminiBaseUrl =
            "https://generativelanguage.googleapis.com/v1beta/models";

    // Model path segment, e.g., "gemini-2.5-flash-lite"
    static const String geminiModel = "gemini-2.5-flash-lite";

    // Runtime API key sourced from environment.
    // Priority: dart-define (best for Web/CI) > .env (mobile/desktop dev).
    // Returns empty string if unset.
    static String get geminiApiKey {
        const defineKey = String.fromEnvironment('GEMINI_API_KEY');
        if (defineKey.isNotEmpty) return defineKey.trim();
        // Access dotenv only if initialized to avoid NotInitializedError (Web).
        try {
            if (dotenv.isInitialized) {
                return dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
            }
        } catch (_) {
            // Swallow and fall through to empty.
        }
        return '';
    }
}
