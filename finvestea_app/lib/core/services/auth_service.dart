import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── AuthUser ──────────────────────────────────────────────────────────────────

class AuthUser {
  final String uid;
  final String email;
  final String? displayName;

  const AuthUser({required this.uid, required this.email, this.displayName});

    factory AuthUser.fromFirebase(fb.User user) => AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email?.split('@').first,
      );
}

// ─── AuthException ─────────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String code;
  final String? message;

  const AuthException({required this.code, this.message});

  @override
  String toString() => message ?? code;
}

// ─── AuthService ───────────────────────────────────────────────────────────────
// Fully local, no network calls. Accepts any valid-looking credentials.

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // AuthUser? _currentUser;
  // final _controller = StreamController<AuthUser?>.broadcast();

  // AuthUser? get currentUser => _currentUser;
  // Stream<AuthUser?> get authStateChanges => _controller.stream;
  

    // Firebase handles ───────────────────────────────────────────────────────────
  final fb.FirebaseAuth _fbAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // SharedPreferences key for cached display-name
  static const _kDisplayName = 'auth_display_name';

  // ─── currentUser ────────────────────────────────────────────────────────────
  // Wraps the live Firebase User so callers always get a fresh reference.
  AuthUser? get currentUser {
    final user = _fbAuth.currentUser;
    if (user == null) return null;
    return AuthUser.fromFirebase(user);
  }

  // ─── authStateChanges ────────────────────────────────────────────────────────
  // Bridges Firebase's stream to our AuthUser? type so GoRouter's
  // _AuthNotifier can listen without knowing about firebase_auth.
  Stream<AuthUser?> get authStateChanges =>
      _fbAuth.authStateChanges().map((user) {
        if (user == null) return null;
        return AuthUser.fromFirebase(user);
      });

  // ─────────────────────────────────────────
  // Email / Password
  // ─────────────────────────────────────────

  // Future<AuthUser> signInWithEmail({
  //   required String email,
  //   required String password,
  // }) async {
  //   await Future.delayed(const Duration(milliseconds: 600));
  //   if (!email.contains('@')) {
  //     throw const AuthException(
  //       code: 'invalid-email',
  //       message: 'Please enter a valid email address.',
  //     );
  //   }
  //   if (password.isEmpty) {
  //     throw const AuthException(
  //       code: 'wrong-password',
  //       message: 'Incorrect password. Please try again.',
  //     );
  //   }
  //   _currentUser = AuthUser(
  //     uid: 'local_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
  //     email: email,
  //     displayName: email.split('@').first,
  //   );
  //   _controller.add(_currentUser);
  //   return _currentUser!;
  // }

    Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _fbAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await _cacheDisplayName(user.displayName ?? email.split('@').first);
      return AuthUser.fromFirebase(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // Future<AuthUser> signUpWithEmail({
  //   required String email,
  //   required String password,
  // }) async {
  //   await Future.delayed(const Duration(milliseconds: 600));
  //   if (!email.contains('@')) {
  //     throw const AuthException(
  //       code: 'invalid-email',
  //       message: 'Please enter a valid email address.',
  //     );
  //   }
  //   if (password.length < 6) {
  //     throw const AuthException(
  //       code: 'weak-password',
  //       message: 'Password must be at least 6 characters.',
  //     );
  //   }
  //   _currentUser = AuthUser(
  //     uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
  //     email: email,
  //     displayName: email.split('@').first,
  //   );
  //   _controller.add(_currentUser);
  //   return _currentUser!;
  // }

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _fbAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      // Set displayName from email prefix
      final displayName = email.split('@').first;
      await user.updateDisplayName(displayName);
      await user.reload();

      // Write user profile to Firestore
      await _createUserProfile(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName,
      );

      await _cacheDisplayName(displayName);

      return AuthUser(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }


  // Future<void> sendPasswordReset(String email) async {
  //   await Future.delayed(const Duration(milliseconds: 500));
  //   // Local mode: no-op (snackbar in UI says "email sent")
  // }

    Future<void> sendPasswordReset(String email) async {
    try {
      await _fbAuth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ─────────────────────────────────────────
  // Phone OTP
  // ─────────────────────────────────────────

  // Future<void> sendOTP({
  //   required String phoneNumber,
  //   required Function(String verificationId) onCodeSent,
  //   required Function(AuthException e) onError,
  //   VoidCallback? onAutoVerified,
  // }) async {
  //   await Future.delayed(const Duration(milliseconds: 800));
  //   // Mock verification ID encodes the phone number for use in verifyOTP
  //   onCodeSent('mock_otp_$phoneNumber');
  // }

  // Future<AuthUser?> verifyOTP({
  //   required String verificationId,
  //   required String smsCode,
  // }) async {
  //   await Future.delayed(const Duration(milliseconds: 600));
  //   // Accept any 6-digit code
  //   if (smsCode.length != 6) {
  //     throw const AuthException(
  //       code: 'invalid-verification-code',
  //       message: 'Invalid OTP. Please check and try again.',
  //     );
  //   }
  //   final phone = verificationId.replaceFirst('mock_otp_', '');
  //   _currentUser = AuthUser(
  //     uid: 'local_phone_$phone',
  //     email: '$phone@phone.local',
  //     displayName: phone,
  //   );
  //   _controller.add(_currentUser);
  //   return _currentUser;
  // }

  // Future<void> resendOTP({
  //   required String phoneNumber,
  //   required Function(String verificationId) onCodeSent,
  //   required Function(AuthException e) onError,
  //   VoidCallback? onAutoVerified,
  // }) async {
  //   await sendOTP(
  //     phoneNumber: phoneNumber,
  //     onCodeSent: onCodeSent,
  //     onError: onError,
  //     onAutoVerified: onAutoVerified,
  //   );
  // }

  // // ─────────────────────────────────────────
  // // Common
  // // ─────────────────────────────────────────

  // Future<void> signOut() async {
  //   _currentUser = null;
  //   _controller.add(null);
  // }


  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(AuthException e) onError,
    VoidCallback? onAutoVerified,
  }) async {
    // Firebase expects E.164 format: +91XXXXXXXXXX for India
    final formatted = phoneNumber.startsWith('+')
        ? phoneNumber
        : '+91$phoneNumber';

    await _fbAuth.verifyPhoneNumber(
      phoneNumber: formatted,
      // ── Auto-retrieval (Android SMS reader) ──
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        try {
          final cred = await _fbAuth.signInWithCredential(credential);
          final user = cred.user!;
          await _ensurePhoneUserProfile(user);
          onAutoVerified?.call();
        } catch (_) {
          // Auto-verification failure is non-fatal; user can enter OTP manually
        }
      },
      // ── Code sent successfully ────────────────
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      // ── Hard errors (invalid number, quota, …) ─
      verificationFailed: (fb.FirebaseAuthException e) {
        onError(_mapFirebaseError(e));
      },
      // ── Code auto-retrieval timeout ───────────
      codeAutoRetrievalTimeout: (_) {
        // No action needed — user can still type the OTP manually
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<AuthUser?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (smsCode.length != 6) {
      throw const AuthException(
        code: 'invalid-verification-code',
        message: 'Invalid OTP. Please check and try again.',
      );
    }
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final cred = await _fbAuth.signInWithCredential(credential);
      final user = cred.user!;
      await _ensurePhoneUserProfile(user);
      return AuthUser.fromFirebase(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<void> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(AuthException e) onError,
    VoidCallback? onAutoVerified,
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: onAutoVerified,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Sign out
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _fbAuth.signOut();
    // Clear cached display-name
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDisplayName);
  }

  // String getErrorMessage(AuthException e) {
  //   switch (e.code) {
  //     case 'invalid-phone-number':
  //       return 'Invalid phone number format.';
  //     case 'too-many-requests':
  //       return 'Too many requests. Please try again later.';
  //     case 'invalid-verification-code':
  //       return 'Invalid OTP. Please check and try again.';
  //     case 'code-expired':
  //       return 'OTP has expired. Please request a new one.';
  //     case 'user-not-found':
  //       return 'No account found with this email.';
  //     case 'wrong-password':
  //       return 'Incorrect password. Please try again.';
  //     case 'invalid-credential':
  //       return 'Incorrect email or password. Please try again.';
  //     case 'email-already-in-use':
  //       return 'An account with this email already exists.';
  //     case 'invalid-email':
  //       return 'Please enter a valid email address.';
  //     case 'weak-password':
  //       return 'Password must be at least 6 characters.';
  //     case 'user-disabled':
  //       return 'This account has been disabled.';
  //     default:
  //       return e.message ?? 'An error occurred. Please try again.';
  //   }
  // }

    String getErrorMessage(AuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'code-expired':
        return 'OTP has expired. Please request a new one.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  
  // ─────────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Maps a FirebaseAuthException to our AuthException type.
  /// Normalises the inconsistent Firebase error codes across SDK versions.
  AuthException _mapFirebaseError(fb.FirebaseAuthException e) {
    // Firebase sometimes returns "INVALID_LOGIN_CREDENTIALS" instead of the
    // granular codes in newer SDK versions — normalise it.
    final code = (e.code == 'INVALID_LOGIN_CREDENTIALS' ||
            e.code == 'invalid-login-credentials')
        ? 'invalid-credential'
        : e.code;
    return AuthException(code: code, message: e.message);
  }

  /// Creates a Firestore user-profile document on first email sign-up.
  /// Uses merge:true so partial updates (e.g. adding phone later) are safe.
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      await _db.collection('users').doc(uid).set(
        {
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'email',
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Non-fatal — the user is authenticated even if Firestore write fails
    }
  }

  /// Creates / updates a minimal Firestore profile for phone-OTP users.
  Future<void> _ensurePhoneUserProfile(fb.User user) async {
    try {
      final phone = user.phoneNumber ?? '';
      final displayName = phone.isNotEmpty ? phone : user.uid.substring(0, 8);
      await user.updateDisplayName(displayName);

      await _db.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'phone': phone,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'phone',
        },
        SetOptions(merge: true),
      );
      await _cacheDisplayName(displayName);
    } catch (_) {
      // Non-fatal
    }
  }

  /// Persists the display-name locally so the Dashboard greets the user
  /// instantly without waiting for a Firestore read.
  Future<void> _cacheDisplayName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDisplayName, name);
    } catch (_) {}
  }
}
