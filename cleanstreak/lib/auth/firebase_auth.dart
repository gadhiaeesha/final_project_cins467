import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member.dart';
import '../firestore_db/member_storage.dart';

class FirebaseAuthService {
  // Create an instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MemberStorage _memberStorage = MemberStorage();

  // Properties to store user info
  String? uid;
  String? userEmail;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailPass(String email, String password) async {
    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = userCredential.user;

      if (user != null) {
        // Store user info
        uid = user.uid;
        userEmail = user.email;

        // Store auth state in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth', true);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is badly formatted.';
      } else {
        throw e.message ?? 'An error occurred during sign in.';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailPass(String email, String password) async {
    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Store user info
        uid = user.uid;
        userEmail = user.email;

        // Create initial Member record
        final member = Member(
          userId: user.uid,
          email: email,
          role: 'member',
          joinedAt: DateTime.now(),
        );
        await _memberStorage.saveMember(member);

        // Store auth state in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth', true);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'An account already exists for this email.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is badly formatted.';
      } else {
        throw e.message ?? 'An error occurred during registration.';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear stored auth state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth', false);

      // Clear user info
      uid = null;
      userEmail = null;
    } catch (e) {
      throw 'Error signing out. Try again.';
    }
  }

  // Check if user is already logged in
  Future<bool> isUserLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool authSignedIn = prefs.getBool('auth') ?? false;

      final User? user = _auth.currentUser;

      if (authSignedIn && user != null) {
        uid = user.uid;
        userEmail = user.email;
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
