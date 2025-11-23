import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// RemoteResourceService
/// Lightweight HTTP client for motivational quotes used by `resources.dart`.
/// Current provider: RealInspire (https://api.realinspire.live/v1/quotes/random)
///  - No API key required; permissive CORS (works on Flutter Web)
///  - Returns a single random quote as a one-element JSON array
/// Example response:
///   [{"content":"No one ever is defeated...","author":"Napoleon Hill","authorSlug":"napoleon-hill","length":68}]
/// Behavior:
///  1. Performs a single GET per refresh.
///  2. On success: maps to internal `Quote` (source = RealInspire).
///  3. On failure: returns a rotation from a small in-memory fallback list (marked `isFallback`).
///  4. Logs first failure only to avoid console spam in debug sessions.
/// The service intentionally avoids persistent storage or large batch caching to remain simple
/// and deterministic for the assignment rubric while showcasing HTTP + graceful degradation.
class RemoteResourceService {
  RemoteResourceService._();
  static final instance = RemoteResourceService._();
  static const _realInspireEndpoint = 'https://api.realinspire.live/v1/quotes/random';
  final _rand = Random();
  bool _loggedFailure = false;

  static const List<Quote> _fallbackList = [
    Quote(text: 'You are doing your best.', author: 'Aurora', isFallback: true, source: 'Fallback'),
    Quote(text: 'Small steps still move you forward.', author: 'Aurora', isFallback: true, source: 'Fallback'),
    Quote(text: 'Rest is productive too.', author: 'Aurora', isFallback: true, source: 'Fallback'),
  ];

  Future<Quote> fetchRandomQuote({http.Client? client}) async {
    client ??= http.Client();
    try {
      final resp = await client.get(Uri.parse(_realInspireEndpoint));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map<String, dynamic>) {
            final text = (first['content'] as String?)?.trim();
            final author = (first['author'] as String?)?.trim();
            if (text != null && text.isNotEmpty) {
              return Quote(
                text: text,
                author: (author == null || author.isEmpty) ? 'Unknown' : author,
                isFallback: false,
                source: 'RealInspire',
              );
            }
          }
          throw const FormatException('Unexpected RealInspire item shape');
        }
        throw const FormatException('RealInspire returned empty array');
      }
      throw HttpException('Status ${resp.statusCode}');
    } catch (e) {
      if (kDebugMode && !_loggedFailure) {
        debugPrint('RealInspire fetch failed: $e');
        _loggedFailure = true;
      }
      return _fallbackList[_rand.nextInt(_fallbackList.length)];
    } finally {
      client.close();
    }
  }
}

/// Lightweight domain model for a motivational quote used in the resources UI.
class Quote {
  final String text;
  final String author;
  final bool isFallback; // true if served from local fallback list
  final String source; // 'RealInspire' | 'Fallback'
  const Quote({required this.text, required this.author, required this.isFallback, required this.source});
}

/// Simple custom HttpException for clearer error semantics without importing
/// dart:io exceptions (which are unavailable on web).
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException($message)';
}