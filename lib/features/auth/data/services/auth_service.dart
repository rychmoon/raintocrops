import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/auth_results.dart';
import '../mappers/auth_exception_mapper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<bool> doesUserExistByEmail({required String email}) async {
    try {
      final normalizedEmail = _normalizeEmail(email);

      if (normalizedEmail.isEmpty) return false;

      final query = await _users
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  List<String> _mapProvidersFromFirebase(User user) {
    final providers = user.providerData
        .map((e) => e.providerId)
        .where((id) => id.isNotEmpty)
        .map((id) {
      if (id == 'password') return 'password';
      if (id == 'google.com') return 'google';
      return id;
    })
        .toSet()
        .toList();

    if (providers.isEmpty && user.email != null) {
      return ['password'];
    }

    return providers;
  }

  String _firstNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return '';
    return displayName.trim().split(RegExp(r'\s+')).first;
  }

  String _lastNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return '';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ');
  }

  Future<UserModel> _buildFallbackUser({
    required User firebaseUser,
    required String fallbackEmail,
    DocumentSnapshot<Map<String, dynamic>>? existingDoc,
  }) async {
    final doc = existingDoc ?? await _users.doc(firebaseUser.uid).get();

    if (doc.exists && doc.data() != null) {
      final existingModel = UserModel.fromMap(doc.data()!, doc.id);

      final updatedUser = UserModel(
        uid: firebaseUser.uid,
        firstName: existingModel.firstName.isNotEmpty
            ? existingModel.firstName
            : _firstNameFromDisplayName(firebaseUser.displayName),
        lastName: existingModel.lastName.isNotEmpty
            ? existingModel.lastName
            : _lastNameFromDisplayName(firebaseUser.displayName),
        email: firebaseUser.email ?? fallbackEmail,
        providers: _mapProvidersFromFirebase(firebaseUser),
        role: existingModel.role,
        allowedCodes: existingModel.allowedCodes,
        photoUrl: existingModel.photoUrl,
        googlePhotoUrl: existingModel.googlePhotoUrl,
        hideGooglePhoto: existingModel.hideGooglePhoto,
        createdAt: existingModel.createdAt,
      );

      await _users.doc(firebaseUser.uid).set(
        updatedUser.toMap(),
        SetOptions(merge: true),
      );

      return updatedUser;
    }

    final user = UserModel(
      uid: firebaseUser.uid,
      firstName: _firstNameFromDisplayName(firebaseUser.displayName),
      lastName: _lastNameFromDisplayName(firebaseUser.displayName),
      email: firebaseUser.email ?? fallbackEmail,
      providers: _mapProvidersFromFirebase(firebaseUser),
      role: 'viewer',
      allowedCodes: const [],
      photoUrl: null,
      googlePhotoUrl: null,
      hideGooglePhoto: false,
    );

    await _users.doc(firebaseUser.uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );

    return user;
  }

  Future<void> _sendVerificationEmailSafely(User user) async {
    try {
      await user.sendEmailVerification().timeout(
        const Duration(seconds: 4),
      );
    } catch (_) {
      // Intentionally ignored so registration can still finish fast.
    }
  }

  Future<AuthResult<UserModel>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    User? createdUser;

    try {
      final normalizedEmail = _normalizeEmail(email);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthResult(
          status: AuthStatus.unknownError,
          message: 'Registration failed. Please try again.',
        );
      }

      createdUser = firebaseUser;

      final user = UserModel(
        uid: firebaseUser.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: normalizedEmail,
        providers: const ['password'],
        role: 'viewer',
        allowedCodes: const [],
        photoUrl: null,
        googlePhotoUrl: null,
        hideGooglePhoto: false,
      );

      await _users.doc(user.uid).set(
        user.toMap(),
        SetOptions(merge: true),
      );

      unawaited(_sendVerificationEmailSafely(firebaseUser));

      return AuthResult(
        status: AuthStatus.success,
        data: user,
        message: 'Account created successfully. Please verify your email.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<UserModel>(e);
    } on FirebaseException {
      try {
        await createdUser?.delete();
      } catch (_) {}

      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Failed to save your account data. Please try again.',
      );
    } catch (_) {
      try {
        await createdUser?.delete();
      } catch (_) {}

      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<AuthResult<UserModel>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);

      final cred = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null) {
        return const AuthResult(
          status: AuthStatus.unknownError,
          message: 'Login failed.',
        );
      }

      if (!firebaseUser.emailVerified) {
        await _auth.signOut();
        return const AuthResult(
          status: AuthStatus.emailNotVerified,
          message: 'Please verify your email before logging in.',
        );
      }

      final doc = await _users.doc(firebaseUser.uid).get();

      if (doc.exists && doc.data() != null) {
        return AuthResult(
          status: AuthStatus.success,
          data: UserModel.fromMap(doc.data()!, doc.id),
          message: 'Login successful.',
        );
      }

      final fallbackUser = await _buildFallbackUser(
        firebaseUser: firebaseUser,
        fallbackEmail: normalizedEmail,
        existingDoc: doc,
      );

      return AuthResult(
        status: AuthStatus.success,
        data: fallbackUser,
        message: 'Login successful.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<UserModel>(e);
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<AuthResult<void>> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return const AuthResult(
          status: AuthStatus.unknownError,
          message: 'No active user found.',
        );
      }

      await user.sendEmailVerification().timeout(
        const Duration(seconds: 8),
      );

      return const AuthResult(
        status: AuthStatus.success,
        message: 'Verification email sent successfully.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<void>(e);
    } on TimeoutException {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Verification email is taking too long. Please try again.',
      );
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Failed to send verification email. Please try again.',
      );
    }
  }

  Future<AuthResult<void>> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);

      if (normalizedEmail.isEmpty) {
        return const AuthResult(
          status: AuthStatus.invalidEmail,
          message: 'Please enter your email address.',
        );
      }

      await _auth.sendPasswordResetEmail(
        email: normalizedEmail,
        actionCodeSettings: actionCodeSettings,
      );

      return const AuthResult(
        status: AuthStatus.passwordResetEmailSent,
        message:
        'If an account exists for this email, a reset link has been sent.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<void>(e);
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Failed to send password reset email. Please try again.',
      );
    }
  }

  Future<AuthResult<ActionCodeInfo>> verifyPasswordResetCode({
    required String oobCode,
  }) async {
    try {
      final info = await _auth.checkActionCode(oobCode);

      if (info.operation != ActionCodeInfoOperation.passwordReset) {
        return const AuthResult(
          status: AuthStatus.unknownError,
          message: 'This reset link is invalid.',
        );
      }

      return AuthResult(
        status: AuthStatus.success,
        data: info,
        message: 'Reset link verified.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<ActionCodeInfo>(e);
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Invalid or expired reset link.',
      );
    }
  }

  Future<AuthResult<void>> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(
        code: oobCode,
        newPassword: newPassword,
      );

      return const AuthResult(
        status: AuthStatus.success,
        message: 'Password reset successful.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<void>(e);
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Failed to reset password. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}