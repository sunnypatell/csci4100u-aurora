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
}