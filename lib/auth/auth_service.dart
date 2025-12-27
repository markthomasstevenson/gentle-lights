import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in anonymously for user role
  /// If user is already signed in, returns null (no action needed)
  Future<UserCredential?> signInAnonymously() async {
    try {
      // If already signed in, no need to sign in again
      if (_auth.currentUser != null) {
        return null;
      }
      return await _auth.signInAnonymously();
    } catch (e) {
      // TODO: Handle error
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user role (to be implemented with Firestore)
  Future<UserRole?> getUserRole() async {
    // TODO: Fetch from Firestore based on user ID
    return null;
  }
}



