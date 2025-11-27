import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/ai_constants.dart';

/// ai_service.dart
/// Minimal Gemini integration to support two flows:
/// - getJournalInsight(entryText, usermood): one-shot prompt for helpful tips
/// - chatWithContext(userMessage, chatHistory, userContext?, journalContext?):
///   simple conversational prompt (no Firestore wiring yet)
///
/// Uses a singleton to avoid multiple http client instances.
class AiService {
  AiService._internal();
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  String get _apiKey => AiConstants.geminiApiKey;
  String get _baseUrl => AiConstants.geminiBaseUrl;
  String get _modelPath => AiConstants.geminiModel;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// One-shot journal insight generator.
  Future<String> getJournalInsight({
    required String journalText,
    required String usermood,
  }) async {
    if (!isConfigured) {
      return "AI is not set up yet. Please add an API key.";
    }

    try {
      final prompt = _buildPrompt(entryText: journalText, mood: usermood);
      final uri = Uri.parse("$_baseUrl/$_modelPath:generateContent?key=$_apiKey");

      final body = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      };

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        return "Sorry, I couldn't generate insight right now. (Error ${response.statusCode})";
      }

      final data = jsonDecode(response.body);
      final text = _extractText(data);
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
      return "I couldn't find anything meaningful to say about this entry.";
    } catch (e) {
      return "Something went wrong while generating AI insight: $e";
    }
  }

  /// Simple conversational chat without Firestore context.
  Future<String> chatWithContext({
    required String userMessage,
    required List<Map<String, String>> chatHistory,
    String? userContext,
    String? journalContext,
  }) async {
    if (!isConfigured) {
      return "AI is not set up yet. Please add an API key.";
    }

    try {
      final prompt = _buildChatPrompt(
        userMessage: userMessage,
        chatHistory: chatHistory,
        userContext: userContext,
        journalContext: journalContext,
      );

      final uri = Uri.parse("$_baseUrl/$_modelPath:generateContent?key=$_apiKey");
      final body = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      };

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        return "Sorry, I'm having trouble right now. Try again?";
      }

      final data = jsonDecode(response.body);
      final text = _extractText(data);
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
      return "I'm not sure what to say. Can you tell me more?";
    } catch (e) {
      return "Something went wrong. Let's try that again?";
    }
  }

  /// Extracts the first text candidate from Gemini response format.
  String? _extractText(dynamic data) {
    try {
      final candidates = data["candidates"] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final content = candidates.first["content"];
      final parts = content["parts"] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;
      return parts.first["text"] as String?;
    } catch (_) {
      return null;
    }
  }

  // Conversational prompt (Suthashan's tone and structure preserved).
  String _buildChatPrompt({
    required String userMessage,
    required List<Map<String, String>> chatHistory,
    String? userContext,
    String? journalContext,
  }) {
    String prompt =
        """You are Aurora, a supportive AI companion for university students dealing with mental health challenges.

You help students by:
- Being warm, empathetic, and non-judgmental
- Listening to their feelings and validating their experiences
- Offering practical coping strategies and suggestions
- Encouraging them to take small, manageable steps
- Never diagnosing or pretending to be a therapist

""";

    if (userContext != null && userContext.isNotEmpty) {
      prompt += "STUDENT INFO:\n$userContext\n\n";
    }
    if (journalContext != null && journalContext.isNotEmpty) {
      prompt += "RECENT JOURNAL ENTRIES:\n$journalContext\n\n";
    }
    if (chatHistory.isNotEmpty) {
      prompt += "CONVERSATION SO FAR:\n";
      for (var message in chatHistory) {
        final role = message['isUser'] == 'true' ? 'Student' : 'Aurora';
        prompt += "$role: ${message['text']}\n";
      }
      prompt += "\n";
    }

    prompt += "Student: $userMessage\n\nAurora:";
    return prompt;
  }

  // Structured journaling insight prompt
  String _buildPrompt({
    required String entryText,
    required String mood,
  }) {
    return """
You are a warm, supportive journaling companion for a university student.
You are not a therapist — just a kind, steady presence who helps them feel understood and gives small, realistic ideas they can try.

Mood: $mood
Journal Entry:
$entryText

Your job:
1. Reflect how they might be feeling (2-3 sentences).
2. Gently suggest what might be going on underneath (stress, pressure, loneliness, overwhelm, etc.).
3. Give 2-3 very small, practical suggestions they can try in the next 24 hours.

Tone:
- Human, calm, non-judgmental.
- No clinical terms or diagnosis.
- No AI disclaimers.
- If the entry sounds hopeless or unsafe, encourage reaching out to someone they trust or local crisis support (without giving harmful details).

Format your response like this:

1) Reflection
2) What might be going on
3) Suggestions (bullet points)

Now respond following this format.
""";
  }
}
