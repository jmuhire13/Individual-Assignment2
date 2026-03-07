import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Get the Firebase Auth instance (the login system)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Get the Firestore instance (the database)
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference for user profiles
  CollectionReference get _usersCollection => _db.collection('users');

  // ── SIGN UP (Assignment: Email/Password with Firestore profile) ─────
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      // 📧 VALIDATION: Check email format
      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      // 🔒 VALIDATION: Check password strength
      if (!_isValidPassword(password)) {
        throw Exception('Password must be at least 6 characters long');
      }

      // 👤 VALIDATION: Check display name
      if (name.trim().isEmpty) {
        throw Exception('Please enter your display name');
      }

      // Step 1: Create the auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Step 2: Send verification email
      try {
        await credential.user!.sendEmailVerification();
      } catch (e) {
        // Don't fail signup if email sending fails
        print('Warning: Could not send verification email: $e');
      }

      // Step 3: Save comprehensive user profile in Firestore
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email.trim().toLowerCase(),
        displayName: name.trim(),
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isEmailVerified: false, // Will be updated when user verifies
        // profileImageUrl and emailVerifiedAt will be null initially
      );

      await _usersCollection.doc(credential.user!.uid).set(userModel.toMap());

      return credential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors with user-friendly messages
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      // Handle other errors
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // ── SIGN IN (Assignment: Secure login with profile update) ────────
  Future<UserCredential> signIn(String email, String password) async {
    try {
      // 📧 VALIDATION: Check email format
      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      if (password.isEmpty) {
        throw Exception('Please enter your password');
      }

      // Attempt sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Update user's last seen timestamp
      if (credential.user != null) {
        try {
          await _updateLastSeen(credential.user!.uid);
          await _updateEmailVerificationStatus(
            credential.user!.uid,
            credential.user!.emailVerified,
          );
        } catch (e) {
          // Don't fail login if profile update fails
          print('Warning: Could not update user profile: $e');
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      // Handle other errors
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // ── SIGN OUT (Assignment: Secure logout with profile update) ──────
  Future<void> signOut() async {
    try {
      // Update last seen before signing out
      if (_auth.currentUser != null) {
        await _updateLastSeen(_auth.currentUser!.uid);
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // ── CURRENT USER (Assignment: Get current authenticated user) ──────
  User? get currentUser => _auth.currentUser;

  // ── USER PROFILE MANAGEMENT (Assignment: Firestore user profiles) ───

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Get current user's profile
  Future<UserModel?> getCurrentUserProfile() async {
    if (_auth.currentUser == null) return null;
    return getUserProfile(_auth.currentUser!.uid);
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _usersCollection.doc(updatedUser.uid).update(updatedUser.toMap());
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // ── EMAIL VERIFICATION (Assignment: Email verification requirement) ──

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  // Check and update email verification status
  Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      final isVerified = _auth.currentUser?.emailVerified ?? false;

      if (isVerified) {
        await _updateEmailVerificationStatus(user.uid, true);
      }

      return isVerified;
    } catch (e) {
      throw Exception('Failed to check email verification: ${e.toString()}');
    }
  }

  // ── PASSWORD RESET (Common authentication feature) ─────────────────

  Future<void> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // ── PRIVATE HELPER METHODS ──────────────────────────────────────────

  // Update user's last seen timestamp
  Future<void> _updateLastSeen(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - don't interrupt user experience
      print('Warning: Could not update lastSeen: $e');
    }
  }

  // Update email verification status in Firestore
  Future<void> _updateEmailVerificationStatus(
    String uid,
    bool isVerified,
  ) async {
    try {
      final updateData = <String, dynamic>{'isEmailVerified': isVerified};

      // If just verified, record the timestamp
      if (isVerified) {
        updateData['emailVerifiedAt'] = DateTime.now().toIso8601String();
      }

      await _usersCollection.doc(uid).update(updateData);
    } catch (e) {
      print('Warning: Could not update email verification status: $e');
    }
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Validate password strength
  bool _isValidPassword(String password) {
    return password.length >= 6; // Firebase minimum
  }

  // Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      default:
        return 'An error occurred. Please try again';
    }
  }
}
