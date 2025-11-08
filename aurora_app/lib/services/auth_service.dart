import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signUp({required String email, required String password, required String displayName}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    return cred.user;
  }

  Future<User?> signIn({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<void> signOut() async => _auth.signOut();
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String mapAuthError(Exception e) {
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
        default:
          return e.message ?? 'Authentication error';
      }
    }
    return 'Unexpected error';
  }
}
