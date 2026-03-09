import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _userProfile; // NEW: Store current user's profile data

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _service.currentUser;
  UserModel? get userProfile => _userProfile; // NEW: Access user profile data

  // ── SIGN UP (Assignment: Email/Password with profile creation) ────
  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.signUp(email, password, name);

      // After successful signup, load user profile
      await _loadUserProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString(); // Use improved error messages from AuthService
      notifyListeners();
      return false;
    }
  }

  // ── SIGN IN (Assignment: Secure login with profile loading) ───────
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.signIn(email, password);

      // After successful login, load user profile
      await _loadUserProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapFirebaseError(e.code);  // ← map code to friendly message
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ── MAP FIREBASE ERROR CODES TO FRIENDLY MESSAGES ─────────────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Invalid email or password. Please check your credentials.';
    }
  }

  // ── SIGN OUT (Assignment: Secure logout) ────────────────────────
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.signOut();
      _userProfile = null; // Clear user profile data
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ── EMAIL VERIFICATION (Assignment: Email verification required) ───

  // Resend verification email
  Future<bool> resendVerificationEmail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.resendVerificationEmail();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      final isVerified = await _service.checkEmailVerification();

      // If verified, update profile data
      if (isVerified) {
        await _loadUserProfile();
      }

      return isVerified;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── PASSWORD RESET ─────────────────────────────────────────────────

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── USER PROFILE MANAGEMENT (Assignment: Settings screen) ──────────

  // Load current user's profile from Firestore
  Future<void> loadUserProfile() async {
    await _loadUserProfile();
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel updatedProfile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── HELPER METHODS ──────────────────────────────────────────────────

  // Private method to load user profile
  Future<void> _loadUserProfile() async {
    try {
      if (currentUser != null) {
        _userProfile = await _service.getUserProfile(currentUser!.uid);
        notifyListeners();
      }
    } catch (e) {
      // Don't show error for profile loading failure
      print('Warning: Could not load user profile: $e');
    }
  }

  // ── UTILITY METHODS ─────────────────────────────────────────────────

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize provider (call this when app starts)
  Future<void> initialize() async {
    // If user is already logged in, load their profile
    if (currentUser != null) {
      await _loadUserProfile();
    }
  }

  // Check if user is fully authenticated (logged in + email verified)
  bool get isFullyAuthenticated {
    final user = currentUser;
    if (user == null) return false;
    return user.emailVerified;
  }

  // Get user's display name with fallback
  String get displayName {
    if (_userProfile != null) return _userProfile!.displayName;
    if (currentUser != null) return currentUser!.displayName ?? 'User';
    return 'User';
  }

  // Get user's email with fallback
  String get email {
    if (_userProfile != null) return _userProfile!.email;
    if (currentUser != null) return currentUser!.email ?? '';
    return '';
  }
}