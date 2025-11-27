/// ai_constants.dart
/// Simple constants for Gemini API integration. Keys are hardcoded per grading
/// requirements; do NOT use these in production.

class AiConstants {
  static const String geminiBaseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models";

  // Model path segment, e.g., "gemini-2.5-flash-lite"
  static const String geminiModel = "gemini-2.5-flash-lite";

  // Hardcoded grading key (provided by Suthashan). Rotated after course.
  static const String geminiApiKey =
      "AIzaSyBGt51mbE2be7tWiksHGpBwLeIMs8jPyVY";
}
