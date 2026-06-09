import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _didWaitForAuthRestore = false;

  //Stream to watch user changes (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensurePersistenceConfigured() async {
    if (!kIsWeb) return;
    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (_) {
      // Ignore persistence setup failures (e.g. restricted browser storage).
      // Firebase auth will continue with best available persistence.
    }
  }

  Future<void> _waitForAuthRestoreIfNeeded() async {
    await _ensurePersistenceConfigured();
    if (_didWaitForAuthRestore) return;

    if (_auth.currentUser != null) {
      _didWaitForAuthRestore = true;
      return;
    }

    // On some platforms (especially web), restoring a persisted auth session
    // can be async. Waiting for first auth event avoids false logged-out reads.
    await _auth.authStateChanges().first;

    if (_auth.currentUser == null) {
      try {
        // Some browsers emit an initial null before restoring from local storage.
        await _auth
            .authStateChanges()
            .firstWhere((user) => user != null)
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // Timed out waiting for restored user; treat as genuinely logged out.
      }
    }

    _didWaitForAuthRestore = true;
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Ensure persisted auth session is restored before route/auth decisions.
  Future<void> initializeSession() async {
    await _waitForAuthRestoreIfNeeded();
  }

  /// Sign up with email + password
  Future<User?> signUp(String email, String password) async {
    await _ensurePersistenceConfigured();
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Login
  Future<User?> signIn(String email, String password) async {
    await _ensurePersistenceConfigured();
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    await _waitForAuthRestoreIfNeeded();
    return _auth.currentUser != null;
  }

  //Delete account
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
