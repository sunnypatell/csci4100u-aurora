import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// JournalService
/// Lightweight Firestore wrapper for per-user journal CRUD operations.
/// Collection layout: `users/{uid}/journalEntries/{autoId}`.
/// All timestamps use server time for consistency across clients.
/// Throws a FirebaseException with `code: no-current-user` when invoked
/// without an authenticated user.

class JournalService {
  JournalService._();
  static final instance = JournalService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  /// Streams current user's journal entries ordered newest‑first.
  ///
  /// Throws a `FirebaseException(code: no-current-user)` if called while no
  /// user is authenticated (caller should catch and present appropriate UI).
  Stream<QuerySnapshot<Map<String, dynamic>>> journalEntriesStream() {
    final uid = userId;
    if (uid == null) {
      throw FirebaseException(
          plugin: 'auth', code: 'no-current-user', message: 'No authenticated user found.');
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Adds a new journal entry document for the current user.
  /// Trims [title] & [content] and stamps server timestamps for creation + update.
  Future<void> addEntry({
    required String title,
    required String content,
    String mood = 'neutral',
  }) async {
    final uid = userId;
    if (uid == null) {
      throw FirebaseException(
          plugin: 'auth', code: 'no-current-user', message: 'No user signed in.');
    }
    await _db
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .add({
      'title': title.trim(),
      'content': content.trim(),
      'mood': mood,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a journal entry by [entryId] (no-op if it doesn't exist).
  Future<void> deleteEntry(String entryId) async {
    final uid = userId;
    if (uid == null) {
      throw FirebaseException(
          plugin: 'auth', code: 'no-current-user', message: 'No user signed in.');
    }
    await _db
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .doc(entryId)
        .delete();
  }

  /// Updates an existing entry (identified by [entryId]) with provided non‑null fields.
  /// Only changed fields are written; if no changes (besides timestamp) the write is skipped.
  Future<void> updateEntry(
    String entryId, {
    String? title,
    String? content,
    String? mood,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw FirebaseException(
          plugin: 'auth', code: 'no-current-user', message: 'No user signed in.');
    }
    final Map<String, dynamic> update = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (title != null) update['title'] = title.trim();
    if (content != null) update['content'] = content.trim();
    if (mood != null) update['mood'] = mood;
    if (update.length == 1) return; // only timestamp present => skip Firestore write to reduce churn
    await _db
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .doc(entryId)
        .set(update, SetOptions(merge: true));
  }

  /// Fetches a single entry document, returns null if not found.
  /// Caller can distinguish missing documents by a null return versus exception.
  Future<Map<String, dynamic>?> getEntry(String entryId) async {
    final uid = userId;
    if (uid == null) {
      throw FirebaseException(
          plugin: 'auth', code: 'no-current-user', message: 'No user signed in.');
    }
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .doc(entryId)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }
}