import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/ai_service.dart';

/// ai_chat.dart
/// Aurora chat UI (Gemini-backed).
///
/// High-level flow:
/// 1. On screen load we asynchronously build two immutable context blocks:
///    - Journal context: recent entries (date, mood emoji, truncated content).
///    - User profile context: stable attributes (program, pronouns, etc.).
/// 2. We DO NOT create a Firestore conversation until the user sends a first
///    message; this keeps history free of empty placeholders.
/// 3. Each send:
///    - Lazily creates conversation (if needed).
///    - Appends the user message locally & to Firestore.
///    - Builds a lightweight chat history list passed to Gemini.
///    - Receives AI reply, stores it, updates `updatedAt`.
///    - Generates a title exactly once on the first exchange (model prompt
///      with fallback heuristic) to support quick visual scanning in history.
/// 4. History bottom sheet streams conversations ordered by creation time and
///    shows an optional last updated date (no raw IDs).
///
/// Prompt discipline and data minimization:
/// - Journals are truncated per entry to reduce token usage & prevent overly
///   long prompts.
/// - Only the minimal structured chat history (role + text) is sent each turn.
/// - Title generation uses a strict instruction set to avoid verbose output.
///
/// Extensibility notes:
/// - If we later add token counting / cost display, hook after prompt build.
/// - Streaming responses could replace the current single-shot reply with a
///   StreamBuilder and incremental UI painting.
/// - Safety filters (e.g., for crisis language) could be inserted before
///   persisting AI replies.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  String? _journalContext; // built once on load
  String? _userContext; // profile context built once on load
  String? _displayName; // for greeting header

  // Conversation persistence
  String? _conversationId; // current conversation doc id
  String? _conversationTitle; // AI-assigned title

  @override
  void initState() {
    super.initState();
    _loadJournalContext();
    _loadUserContext();
    // Do NOT create a Firestore conversation yet. We only create a document
    // after the user sends the first message so the history list stays clean.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadJournalContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final qs = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    final buffer = StringBuffer();

    // Simple mood emoji mapping for readability
    String moodEmoji(String m) {
      switch (m.toLowerCase()) {
        case 'happy':
        case 'joy':
          return '😊';
        case 'sad':
          return '😔';
        case 'anxious':
        case 'anxiety':
          return '😟';
        case 'angry':
          return '😠';
        case 'neutral':
        default:
          return '🙂';
      }
    }

    // Build a compact, readable summary for Gemini
    buffer.writeln('RECENT JOURNALS (latest ${qs.docs.length}):');
    for (final doc in qs.docs) {
      final d = doc.data();
      final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
      final when = createdAt != null
          ? _formatDate(createdAt)
          : 'Unknown date';
      final mood = (d['mood'] as String?)?.trim().toLowerCase() ?? 'neutral';
      final emoji = moodEmoji(mood);
      final title = ((d['title'] as String?) ?? '').trim();
      final content = ((d['content'] as String?) ?? '').trim();
      final snippet = content.length > 240 ? '${content.substring(0, 240)}…' : content;

      buffer.writeln('- $when [$mood $emoji] ${title.isEmpty ? '(untitled)' : title}');
      if (snippet.isNotEmpty) {
        buffer.writeln('  • ${snippet.replaceAll('\n', ' ')}');
      }
    }

    setState(() {
      _journalContext = buffer.isNotEmpty ? buffer.toString() : null;
    });
  }

  String _formatDate(DateTime dt) {
    // Human-friendly ISO without seconds for brevity, local time
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    // Create the conversation *on first user message*.
    if (_conversationId == null) {
      await _ensureConversation();
    }

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(text: text, fromUser: true));
    });
    await _appendMessageToFirestore(text, fromUser: true);
    _controller.clear();

    final chatHistory = _messages
        .map((m) => {
              'isUser': m.fromUser ? 'true' : 'false',
              'text': m.text,
            })
        .toList();

    final reply = await AiService().chatWithContext(
      userMessage: text,
      chatHistory: chatHistory,
      userContext: _userContext,
      journalContext: _journalContext,
    );

    setState(() {
      _messages.add(_ChatMessage(text: reply, fromUser: false));
      _sending = false;
    });
    await _appendMessageToFirestore(reply, fromUser: false);

    // Generate an AI-based title if missing (first exchange only). We try
    // model-based title first; if empty fall back to heuristic.
    if (_conversationTitle == null) {
      final modelTitle = await AiService().generateConversationTitle(
        userMessage: text,
        aiReply: reply,
        userContext: _userContext,
        journalContext: _journalContext,
      );
      final fallback = _proposeTitleFromExchange(text, reply);
      await _setConversationTitle((modelTitle.trim().isEmpty) ? fallback : modelTitle.trim());
    }
  }

  Future<void> _loadUserContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    String fmtNum(dynamic v) => v == null ? '' : v.toString();

    final displayName = (data['displayName'] as String?)?.trim();
    final pronouns = (data['pronouns'] as String?)?.trim();
    final birthdayTs = data['birthday'];
    final birthday = birthdayTs is Timestamp ? _formatDate(birthdayTs.toDate()) : null;
    final height = fmtNum(data['height']);
    final weight = fmtNum(data['weight']);
    final program = (data['program'] as String?)?.trim();
    final yearOfStudy = fmtNum(data['yearOfStudy']);
    final bio = (data['bio'] as String?)?.trim();

    final buf = StringBuffer();
    buf.writeln('STUDENT PROFILE CONTEXT:');
    if (displayName != null && displayName.isNotEmpty) buf.writeln('- Name: $displayName');
    if (pronouns != null && pronouns.isNotEmpty) buf.writeln('- Pronouns: $pronouns');
    if (birthday != null) buf.writeln('- Birthday: $birthday');
    if (program != null && program.isNotEmpty) buf.writeln('- Program: $program');
    if (yearOfStudy.isNotEmpty) buf.writeln('- Year of Study: $yearOfStudy');
    if (height.isNotEmpty) buf.writeln('- Height: $height');
    if (weight.isNotEmpty) buf.writeln('- Weight: $weight');
    if (bio != null && bio.isNotEmpty) buf.writeln('- Bio: ${bio.replaceAll('\n', ' ')}');

    setState(() {
      _userContext = buf.isNotEmpty ? buf.toString() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5EFE7);
    const ink = Color(0xFF2F2E2C);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aurora Chat', style: TextStyle(color: ink)),
            if (_displayName != null)
              Text(
                'Chatting as ${_displayName!}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.add_circle_outline, color: ink),
            onPressed: _startNewConversation,
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_edu_rounded, color: ink),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Align(
                  alignment:
                      m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: m.fromUser
                          ? const Color(0xFF9AD1C1)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(blurRadius: 10, color: Color(0x14000000), offset: Offset(0, 6)),
                      ],
                    ),
                    child: m.fromUser
                        ? Text(
                            m.text,
                            style: const TextStyle(color: Colors.white),
                          )
                        : _buildFormattedAiMessage(m.text, ink),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: _journalContext == null
                            ? 'Type a message (journal context loading...)'
                            : 'Type a message',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // -------------------- Firestore persistence helpers --------------------

  /// Lazily creates a conversation document. Called only when the user sends
  /// the first message, keeping history free of empty placeholders.
  Future<void> _ensureConversation() async {
    if (_conversationId != null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aiConversations')
        .doc();
    await ref.set({
      'createdAt': FieldValue.serverTimestamp(),
      'title': null, // Will be set after first AI reply
    });
    setState(() {
      _conversationId = ref.id;
    });
  }

  /// Persists a single message inside the current conversation and updates
  /// the parent conversation's `updatedAt` timestamp for sorting in history.
  Future<void> _appendMessageToFirestore(String text, {required bool fromUser}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _conversationId == null) return;
    final convoRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aiConversations')
        .doc(_conversationId);
    final msgRef = convoRef.collection('messages').doc();
    await msgRef.set({
      'text': text,
      'isUser': fromUser,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await convoRef.set({'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  String _proposeTitleFromExchange(String userText, String aiText) {
    // Heuristic: pick a concise phrase based on AI reply first line
    final firstLine = aiText.split('\n').first.trim();
    if (firstLine.length > 48) {
      return '${firstLine.substring(0, 48)}…';
    }
    return firstLine.isEmpty ? 'Conversation' : firstLine;
  }

  Future<void> _setConversationTitle(String title) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _conversationId == null) return;
    final convRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aiConversations')
        .doc(_conversationId);
    await convRef.set({'title': title, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    setState(() {
      _conversationTitle = title;
    });
  }

  void _openHistory() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final convs = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('aiConversations')
            .orderBy('createdAt', descending: true)
            .snapshots();
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: convs,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data?.docs ?? [];
            return SizedBox(
              height: 420,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final title = (d.data()['title'] as String?) ?? '(untitled)';
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    // Hide raw doc id from UI; optionally show last updated timestamp if available
                    subtitle: Builder(builder: (_) {
                      final updatedAt = d.data()['updatedAt'];
                      String? when;
                      if (updatedAt is Timestamp) {
                        final t = updatedAt.toDate();
                        when = '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
                      }
                      return when == null
                          ? const SizedBox.shrink()
                          : Text('Updated: $when', style: const TextStyle(fontSize: 12, color: Colors.black54));
                    }),
                    onTap: () async {
                      // Close sheet first (safe synchronous use of context), then load conversation.
                      Navigator.pop(context);
                      await _loadConversation(d.id);
                    },
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await _deleteConversation(d.id);
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startNewConversation() async {
    // Clear current messages; next user send will create the doc.
    setState(() {
      _messages.clear();
      _conversationId = null;
      _conversationTitle = null;
    });
  }

  Future<void> _loadConversation(String convId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final q = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aiConversations')
        .doc(convId)
        .collection('messages')
        .orderBy('createdAt')
        .get();
    final msgs = q.docs
        .map((d) => _ChatMessage(text: (d['text'] as String?) ?? '', fromUser: (d['isUser'] as bool?) ?? false))
        .toList();
    setState(() {
      _conversationId = convId;
      _messages
        ..clear()
        ..addAll(msgs);
    });
  }

  Future<void> _deleteConversation(String convId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final convRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aiConversations')
        .doc(convId);
    final msgs = await convRef.collection('messages').get();
    for (final m in msgs.docs) {
      await m.reference.delete();
    }
    await convRef.delete();
  }

}

class _ChatMessage {
  final String text;
  final bool fromUser;
  _ChatMessage({required this.text, required this.fromUser});
}

/// Extended lightweight markdown-ish rendering for AI messages.
///
/// Supported patterns (subset chosen for mental-health supportive formatting):
/// - Bold: **text** (simple non-nested detection)
/// - Italic: _text_ or *text* (converted to italic if not part of bullet)
/// - Unordered bullets: leading *, -, or • with optional indentation spaces.
///   Indentation increases left padding (2 spaces ≈ one level).
/// - Ordered bullets: leading "1.", "1)" etc. rendered with number marker.
/// - Nested bullet cleanup: if content itself begins with another bullet
///   marker we strip one layer to avoid duplicate • display.
/// - Headings: lines starting with up to ### become larger/bold text.
/// - Code blocks: lines wrapped by triple backticks ``` become monospaced
///   boxes (no syntax highlight).
/// - Inline code: `snippet` rendered monospaced.
/// - Blank lines: vertical spacing.
/// - Fallback: any unrecognized line becomes a normal RichText line.
///
/// NOT supported (intentionally omitted for simplicity & token focus):
/// tables, block quotes, images, HTML, deep nested styling collisions.
///
/// Safety: if formatting parsing fails, we fall back to a single Text widget.
Widget _buildFormattedAiMessage(String raw, Color ink) {
  try {
    final norm = raw.replaceAll('\r\n', '\n');
    final lines = norm.split('\n');
    final children = <Widget>[];
    bool inCode = false;

    TextSpan parseInline(String line) {
      final spans = <TextSpan>[];

      // First pass: bold segments using **...**
      final boldRegex = RegExp(r'\*\*(.+?)\*\*');
      int cursor = 0;
      for (final match in boldRegex.allMatches(line)) {
        if (match.start > cursor) {
          spans.add(TextSpan(text: line.substring(cursor, match.start)));
        }
        final boldContent = match.group(1)!;
        spans.add(TextSpan(text: boldContent, style: const TextStyle(fontWeight: FontWeight.w600)));
        cursor = match.end;
      }
      if (cursor < line.length) {
        spans.add(TextSpan(text: line.substring(cursor)));
      }

      // Second pass: within non-bold spans add italics using _text_ or *text* not part of **.
      final italicUnderscore = RegExp(r'_(.+?)_');
      final italicAsterisk = RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)');
      final refined = <TextSpan>[];
      for (final span in spans) {
        if (span.style?.fontWeight == FontWeight.w600) {
          refined.add(span); // keep bold as-is
          continue;
        }
        final txt = span.text ?? '';
        int pos = 0;
        // Merge both italic patterns by sequential scanning; underscore first.
        final markers = <RegExpMatch>[];
        markers.addAll(italicUnderscore.allMatches(txt));
        markers.addAll(italicAsterisk.allMatches(txt));
        markers.sort((a,b)=> a.start.compareTo(b.start));
        for (final m in markers) {
          if (m.start > pos) {
            refined.add(TextSpan(text: txt.substring(pos, m.start), style: span.style));
          }
          refined.add(TextSpan(text: m.group(1)!, style: const TextStyle(fontStyle: FontStyle.italic)));
          pos = m.end;
        }
        if (pos < txt.length) {
          refined.add(TextSpan(text: txt.substring(pos), style: span.style));
        }
      }

      // Inline code `snippet` preserving existing styles.
      final codeRegex = RegExp(r'`([^`]+)`');
      final codeFinal = <TextSpan>[];
      for (final span in refined) {
        final txt = span.text ?? '';
        int pos = 0;
        for (final match in codeRegex.allMatches(txt)) {
          if (match.start > pos) {
            codeFinal.add(TextSpan(text: txt.substring(pos, match.start), style: span.style));
          }
            final codeContent = match.group(1)!;
          const codeStyle = TextStyle(fontFamily: 'monospace', backgroundColor: Color(0x14000000));
          final combined = span.style?.merge(codeStyle) ?? codeStyle;
          codeFinal.add(TextSpan(text: codeContent, style: combined));
          pos = match.end;
        }
        if (pos < txt.length) {
          codeFinal.add(TextSpan(text: txt.substring(pos), style: span.style));
        }
      }
      return TextSpan(style: TextStyle(color: ink), children: codeFinal);
    }

    for (final rawLine in lines) {
      final original = rawLine; // keep for indentation calc
      final trimmedRight = original.trimRight();
      final t = trimmedRight.trimLeft();
      // Code block toggling
      if (t.startsWith('```')) {
        inCode = !inCode;
        if (!inCode) {
          children.add(const SizedBox(height: 6));
        }
        continue;
      }
      if (inCode) {
        children.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(trimmedRight, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ));
        continue;
      }
      if (t.isEmpty) {
        children.add(const SizedBox(height: 4));
        continue;
      }
      // Headings
      final heading = RegExp(r'^(#{1,3})\s+(.*)').firstMatch(t);
      if (heading != null) {
        final level = heading.group(1)!.length;
        final content = heading.group(2)!;
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            content.trim(),
            style: TextStyle(
              fontSize: switch (level) { 1 => 20.0, 2 => 18.0, _ => 16.0 },
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ));
        continue;
      }
      // Bullet / ordered list lines
      final bulletMatch = RegExp(r'^(\s*)([*\-•]|\d{1,3}[.)])\s+(.*)').firstMatch(trimmedRight);
      if (bulletMatch != null) {
        final indentSpaces = bulletMatch.group(1)!.length;
        final marker = bulletMatch.group(2)!;
        var content = bulletMatch.group(3)!;
        // Nested bullet cleanup: remove a leading secondary marker
        content = content.replaceFirst(RegExp(r'^[*\-•]\s+'), '');
        final isOrdered = RegExp(r'^\d').hasMatch(marker);
        final displayMarker = isOrdered ? marker.replaceAll(RegExp(r'[)]'), '.').trim() : '•';
        final leftPad = indentSpaces * 2.0; // scale indentation
        children.add(Padding(
          padding: EdgeInsets.only(left: leftPad, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  isOrdered ? displayMarker : displayMarker,
                  style: TextStyle(fontSize: 16, color: ink, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: RichText(text: parseInline(content))),
            ],
          ),
        ));
        continue;
      }
      // Paragraph / fallback
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(text: parseInline(trimmedRight)),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children);
  } catch (_) {
    return Text(raw, style: TextStyle(color: ink));
  }
}
