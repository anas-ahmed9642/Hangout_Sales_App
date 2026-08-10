import 'package:firebase_auth/firebase_auth.dart';
class AuthRepository {
  final FirebaseAuth _auth;
  AuthRepository(this._auth);
    /// Returns the currently logged-in user (if any)
  User? get currentUser => _auth.currentUser;
  
  /// Stream that notifies whenever the authentication state changes
  Stream<User?> authStateChanges(){
    return _auth.authStateChanges();
  }
  /// Login using email and password
Future<UserCredential> signIn ({
  required String email,
  required String password,
}) async{
  return await _auth.signInWithEmailAndPassword(email: email, password: password);
}
/// logout
Future<void> signOut() async{
  await _auth.signOut();
}
}