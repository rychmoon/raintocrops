import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_results.dart';

class AuthExceptionMapper {
  static AuthResult<T> mapFirebaseAuthException<T>(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return AuthResult<T>(
          status: AuthStatus.invalidCredentials,
          message: 'Invalid email or password.',
        );

      case 'user-not-found':
        return AuthResult<T>(
          status: AuthStatus.userNotFound,
          message: 'No account found for that email.',
        );

      case 'email-already-in-use':
        return AuthResult<T>(
          status: AuthStatus.emailAlreadyInUse,
          message: 'That email is already in use.',
        );

      case 'weak-password':
        return AuthResult<T>(
          status: AuthStatus.weakPassword,
          message: 'Password is too weak.',
        );

      case 'invalid-email':
        return AuthResult<T>(
          status: AuthStatus.invalidEmail,
          message: 'Please enter a valid email address.',
        );

      case 'too-many-requests':
        return AuthResult<T>(
          status: AuthStatus.tooManyRequests,
          message: 'Too many attempts. Please try again later.',
        );

      case 'network-request-failed':
        return AuthResult<T>(
          status: AuthStatus.networkError,
          message: 'Network error. Please check your internet connection.',
        );

      case 'account-exists-with-different-credential':
        return AuthResult<T>(
          status: AuthStatus.accountExistsWithDifferentCredential,
          message: e.message ?? 'This account already exists with a different sign-in method.',
          extra: {
            'email': e.email,
            'credential': e.credential,
          },
        );

      case 'google-not-supported':
        return AuthResult<T>(
          status: AuthStatus.googleNotSupported,
          message: e.message ?? 'Google Sign-In is not supported on this platform.',
        );

      case 'missing-id-token':
        return AuthResult<T>(
          status: AuthStatus.missingGoogleIdToken,
          message: e.message ?? 'Google Sign-In failed because no ID token was returned.',
        );

      case 'no-current-user':
        return AuthResult<T>(
          status: AuthStatus.noCurrentUser,
          message: e.message ?? 'No current user found.',
        );

      default:
        return AuthResult<T>(
          status: AuthStatus.unknownError,
          message: e.message ?? 'Something went wrong. Please try again.',
        );
    }
  }
}