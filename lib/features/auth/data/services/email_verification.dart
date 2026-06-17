import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_results.dart';
import '../mappers/auth_exception_mapper.dart';

class EmailVerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<AuthResult<void>> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No current user found.',
        );
      }

      if (user.emailVerified) {
        return const AuthResult(
          status: AuthStatus.success,
          message: 'Email is already verified.',
        );
      }

      await user.sendEmailVerification();

      return const AuthResult(
        status: AuthStatus.success,
        message: 'Verification email sent.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<void>(e);
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Failed to send verification email.',
      );
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<AuthResult<bool>> isEmailVerified() async {
    try {
      await reloadUser();
      final user = _auth.currentUser;

      if (user == null) {
        return const AuthResult(
          status: AuthStatus.noCurrentUser,
          data: false,
          message: 'No current user found.',
        );
      }

      return AuthResult(
        status: AuthStatus.success,
        data: user.emailVerified,
        message: user.emailVerified
            ? 'Email is verified.'
            : 'Email is not verified yet.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<bool>(e);
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        data: false,
        message: 'Failed to check email verification.',
      );
    }
  }

  Future<AuthResult<void>> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No current user found.',
        );
      }

      if (user.emailVerified) {
        return const AuthResult(
          status: AuthStatus.success,
          message: 'Email is already verified.',
        );
      }

      await user.sendEmailVerification();

      return const AuthResult(
        status: AuthStatus.success,
        message: 'Verification email resent successfully.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthExceptionMapper.mapFirebaseAuthException<void>(e);
    } catch (_) {
      return const AuthResult(
        status: AuthStatus.unknownError,
        message: 'Something went wrong while resending the email.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}