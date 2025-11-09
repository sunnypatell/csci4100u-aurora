import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signUp({required String email, required String password, required String displayName}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Update display name in Firebase Auth profile
      await cred.user?.updateDisplayName(displayName);
      await cred.user?.reload();
      final user = _auth.currentUser; // refreshed

      // Create / merge profile document in Firestore
      try {
        final uid = user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fullName': displayName,
          'displayName': displayName, // alias for consistency
          'email': email,
          'authProvider': 'password',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        // ignore: avoid_print
        print('Firestore profile write failed: ${e.code} ${e.message}');
      }

      return user;
    } on FirebaseAuthException {
      rethrow; // let UI map & show friendly message while preserving stack trace
    } on PlatformException catch (e) {
      // Convert to a Firebase-like error for unified handling
      throw FirebaseException(plugin: 'platform', code: e.code, message: e.message);
    } catch (e) {
      // Fallback to generic error type so UI does not show just "Unexpected error"
      throw FirebaseException(plugin: 'auth', code: 'unknown', message: e.toString());
    }
  }

  Future<User?> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException {
      rethrow; // propagate for mapping while preserving stack trace
    } on PlatformException catch (e) {
      throw FirebaseException(plugin: 'platform', code: e.code, message: e.message);
    } catch (e) {
      throw FirebaseException(plugin: 'auth', code: 'unknown', message: e.toString());
    }
  }

  Future<void> updateProfile({String? displayName, DateTime? birthday, double? heightCm, double? weightKg}) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
    try {
      // Update auth profile if displayName provided
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      await user.reload();

      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null && displayName.trim().isNotEmpty) {
        updateData['displayName'] = displayName.trim();
        updateData['fullName'] = displayName.trim(); // keep legacy field in sync
      }
      if (birthday != null) {
        updateData['birthday'] = Timestamp.fromDate(birthday);
      }
      if (heightCm != null) {
        updateData['heightCm'] = heightCm;
      }
      if (weightKg != null) {
        updateData['weightKg'] = weightKg;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw FirebaseException(plugin: 'firestore', code: 'unknown', message: e.toString());
    }
  }

  Future<void> signOut() async => _auth.signOut();
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String mapAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email already in use';
        case 'weak-password':
          return 'Password too weak';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-not-found':
          return 'No user found for that email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'unknown':
          return 'An unexpected error occurred. Please try again.';
        default:
          return e.message ?? 'Authentication error';
      }
    } else if (e is FirebaseException) {
      // Firestore and other Firebase services
      switch (e.code) {
        case 'permission-denied':
          return 'Not allowed to access data (permission denied).';
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again.';
        case 'cancelled':
          return 'Request cancelled. Please try again.';
        case 'unknown':
          return 'An unexpected error occurred. Please try again.';
        default:
          return e.message ?? 'Firebase error occurred';
      }
    }
    return 'Unexpected error';
  }
}
