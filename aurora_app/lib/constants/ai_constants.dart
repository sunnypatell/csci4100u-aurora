// ai_constants.dart
// Centralized constants for Gemini integration.
//
// SECURITY NOTE: The API key here is deliberately hardcoded ONLY for course
// grading convenience. In any real deployment:
// - Never commit raw API keys.
// - Use secure remote config / secret manager (Firebase Remote Config,
//   environment variables, or a backend token proxy).
// - Rotate keys regularly and scope permissions minimally.
//
// Keep this file tiny and dependency-free so it can be swapped out easily
// with a secure loader later.

class AiConstants {
  static const String geminiBaseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models";

  // Model path segment, e.g., "gemini-2.5-flash-lite"
  static const String geminiModel = "gemini-2.5-flash-lite";

  // Hardcoded grading key (provided by Suthashan). Rotated after course.
  static const String geminiApiKey =
      "AIzaSyBGt51mbE2be7tWiksHGpBwLeIMs8jPyVY";
}
