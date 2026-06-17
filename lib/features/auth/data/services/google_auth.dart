import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/auth_results.dart';
import '../mappers/auth_exception_mapper.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _initialized = false;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  static Future<void> initialize() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static String _firstNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return '';
    return displayName.trim().split(RegExp(r'\s+')).first;
  }

  static String _lastNameFromDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return '';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ');
  }

  static List<String> _mapProvidersFromFirebase(User user) {
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

    if (providers.isEmpty) {
      return const ['google'];
    }

    return providers;
  }

  static Future<AuthCredential> _getGoogleCredential() async {
    await initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'google-not-supported',
        message: 'Google Sign-In is not supported on this platform.',
      );
    }

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google Sign-In failed because no ID token was returned.',
        );
      }

      return GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw const _GoogleSignInCancelledException();
    }
  }

  static Future<void> _syncUserToFirestore(User user) async {
    final providers = _mapProvidersFromFirebase(user);
    final doc = await _users.doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      final existingModel = UserModel.fromMap(doc.data()!, doc.id);

      await _users.doc(user.uid).set({
        'email': user.email ?? '',
        'providers': providers,
        'googlePhotoUrl': user.photoURL,
        'photoUrl': existingModel.photoUrl,
        'hideGooglePhoto': existingModel.hideGooglePhoto,
      }, SetOptions(merge: true));
      return;
    }

    final newUser = UserModel(
      uid: user.uid,
      firstName: _firstNameFromDisplayName(user.displayName),
      lastName: _lastNameFromDisplayName(user.displayName),
      email: user.email ?? '',
      providers: providers,
      role: 'viewer',
      allowedCodes: const [],
      photoUrl: null,
      googlePhotoUrl: user.photoURL,
      hideGooglePhoto: false,
    );

    await _users.doc(user.uid).set(newUser.toMap());
  }

  static Future<UserModel?> _readUserModel(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  static Future<UserModel> _buildFallbackUser(User user) async {
    final doc = await _users.doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      final existingModel = UserModel.fromMap(doc.data()!, doc.id);

      final model = UserModel(
        uid: user.uid,
        firstName: existingModel.firstName,
        lastName: existingModel.lastName,
        email: user.email ?? existingModel.email,
        providers: _mapProvidersFromFirebase(user),
        role: existingModel.role,
        allowedCodes: existingModel.allowedCodes,
        photoUrl: existingModel.photoUrl,
        googlePhotoUrl: user.photoURL ?? existingModel.googlePhotoUrl,
        hideGooglePhoto: existingModel.hideGooglePhoto,
        createdAt: existingModel.createdAt,
      );

      await _users.doc(user.uid).set(model.toMap(), SetOptions(merge: true));
      return model;
    }

    final model = UserModel(
      uid: user.uid,
      firstName: _firstNameFromDisplayName(user.displayName),
      lastName: _lastNameFromDisplayName(user.displayName),
      email: user.email ?? '',
      providers: _mapProvidersFromFirebase(user),
      role: 'viewer',
      allowedCodes: const [],
      photoUrl: null,
      googlePhotoUrl: user.photoURL,
      hideGooglePhoto: false,
    );

    await _users.doc(user.uid).set(model.toMap(), SetOptions(merge: true));
    return model;
  }

  static Future<AuthResult<UserModel>> signInWithGoogle() async {
    try {
      final googleCredential = await _getGoogleCredential();
      final userCredential = await _auth.signInWithCredential(googleCredential);

      final user = userCredential.user;
      if (user == null) {
        return const AuthResult(
          status: AuthStatus.unknownError,
          message: 'Google sign-in failed.',
        );
      }

      await _syncUserToFirestore(user);

      final model =
          await _readUserModel(user.uid) ?? await _buildFallbackUser(user);

      return AuthResult(
        status: AuthStatus.success,
        data: model,
        message: 'Signed in with Google successfully.',
      );
    } on _GoogleSignInCancelledException {
      return const AuthResult(
        status: AuthStatus.cancelled,
        message: 'Google sign-in was cancelled.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Google sign-in FirebaseAuthException: ${e.code} - ${e.message}',
      );
      return AuthExceptionMapper.mapFirebaseAuthException<UserModel>(e);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Something went wrong during Google sign-in.',
      );
    }
  }

  static Future<AuthResult<UserModel>> loginWithPasswordAndLinkPendingGoogle({
    required String email,
    required String password,
    required AuthCredential pendingGoogleCredential,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);

      final passwordUserCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = passwordUserCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found after password sign-in.',
        );
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        return const AuthResult(
          status: AuthStatus.unknownError,
          message: 'Account linking failed.',
        );
      }

      if (!refreshedUser.emailVerified) {
        await _auth.signOut();
        return const AuthResult(
          status: AuthStatus.emailNotVerified,
          message: 'Please verify your email before linking Google sign-in.',
        );
      }

      final providerIds =
      refreshedUser.providerData.map((e) => e.providerId).toList();

      if (!providerIds.contains('google.com')) {
        await refreshedUser.linkWithCredential(pendingGoogleCredential);
      }

      await _syncUserToFirestore(refreshedUser);

      final model = await _readUserModel(refreshedUser.uid) ??
          await _buildFallbackUser(refreshedUser);

      return AuthResult(
        status: AuthStatus.success,
        data: model,
        message: 'Google account linked successfully.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Link pending Google FirebaseAuthException: ${e.code} - ${e.message}',
      );
      return AuthExceptionMapper.mapFirebaseAuthException<UserModel>(e);
    } catch (e) {
      debugPrint('Link pending Google error: $e');
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Something went wrong while linking your Google account.',
      );
    }
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}

class _GoogleSignInCancelledException implements Exception {
  const _GoogleSignInCancelledException();
}