enum AuthStatus {
  success,
  cancelled,
  emailNotVerified,
  invalidCredentials,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  networkError,
  accountExistsWithDifferentCredential,
  googleNotSupported,
  missingGoogleIdToken,
  noCurrentUser,
  passwordResetEmailSent,
  googleAccountOnly,
  unknownError,
}

class AuthResult<T> {
  final AuthStatus status;
  final T? data;
  final String? message;

  /// Used for Google account linking flow
  final Object? extra;

  const AuthResult({
    required this.status,
    this.data,
    this.message,
    this.extra,
  });

  bool get isSuccess =>
      status == AuthStatus.success ||
          status == AuthStatus.passwordResetEmailSent;
}