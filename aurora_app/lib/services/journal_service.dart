import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalService {
  JournalService._();
  static final instance = JournalService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Stream the current user's journal entries
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

  // New journal entry
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

  // Delete journal entry
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

  // Update an existing entry
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
    if (update.length == 1) return; // nothing to update besides timestamp
    await _db
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .doc(entryId)
        .set(update, SetOptions(merge: true));
  }

  // Get a single entry (returns null if not found)
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