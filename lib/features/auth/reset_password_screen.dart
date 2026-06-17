import 'dart:async';

import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '/features/auth/data/models/auth_results.dart';
import '/features/auth/data/services/auth_service.dart';
import '/features/auth/password_success.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  bool _isSending = false;
  bool _isContinuing = false;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  bool _hasLeftApp = false;
  bool _hasReturnedToApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _hasLeftApp = true;
    }

    if (state == AppLifecycleState.resumed &&
        _hasLeftApp &&
        widget.isExistingUser) {
      setState(() {
        _hasReturnedToApp = true;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
          content: _SnackBarContent(
            icon: isError ? Icons.error_outline : Icons.check_circle_outline,
            message: message,
          ),
        ),
      );
  }

  void _startCooldown([int seconds = 30]) {
    _cooldownTimer?.cancel();

    setState(() {
      _cooldownSeconds = seconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  Future<void> _resendResetLink() async {
    if (_isSending || _cooldownSeconds > 0) return;

    if (!widget.isExistingUser) {
      _showSnackBar(
        'This reset request is not valid.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
      _hasLeftApp = false;
      _hasReturnedToApp = false;
    });

    try {
      final result = await _authService.sendPasswordResetEmail(
        email: widget.email,
      );

      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      final isSuccess = result.status == AuthStatus.success ||
          result.status == AuthStatus.passwordResetEmailSent;

      if (isSuccess) {
        _showSnackBar(
          'Reset link sent.',
          isError: false,
        );
        _startCooldown(30);
      } else {
        _showSnackBar(
          result.message ?? 'Failed to resend reset email.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      _showSnackBar(
        'Failed to resend reset email.',
        isError: true,
      );
    }
  }

  Future<void> _continueAction() async {
    if (_isContinuing) return;

    if (!widget.isExistingUser) {
      _showSnackBar(
        'This reset request is not valid.',
        isError: true,
      );
      return;
    }

    if (!_hasReturnedToApp) {
      _showSnackBar(
        'Open the reset link first.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isContinuing = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isContinuing = false;
    });

    _showSnackBar(
      'Successfully changed password.',
      isError: false,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PasswordSuccessScreen(),
      ),
    );
  }

  Widget _buildProgressBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: index == 1 ? Colors.blue : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canResend =
        widget.isExistingUser && !_isSending && _cooldownSeconds == 0;
    final bool isBusy = _isSending || _isContinuing;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      bottomNavigationBar: _buildProgressBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.04 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.sms_tracking_outline,
                    size: 32,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Reset your password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'We sent a password reset link to\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 18,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Open your inbox and tap the password reset link in the email.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_reset_outlined,
                          size: 18,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'After opening the reset link, return to the app.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasReturnedToApp
                                ? 'You returned to the app. If you already completed the reset from your email, you can continue now.'
                                : 'If you don’t see the email, check your spam or junk folder.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _continueAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.blue.withAlpha(140),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isContinuing
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    _hasReturnedToApp
                        ? 'Continue'
                        : "I've reset my password",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Didn’t receive the email?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    InkWell(
                      onTap: canResend ? _resendResetLink : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        child: Text(
                          _isSending
                              ? 'Sending...'
                              : _cooldownSeconds > 0
                              ? '${_cooldownSeconds}s'
                              : 'Click this to resend',
                          style: TextStyle(
                            fontSize: 12,
                            color: canResend
                                ? Colors.lightBlue
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: canResend
                                ? Colors.lightBlue
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: isBusy ? null : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    size: 14,
                    color: isBusy
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF374151),
                  ),
                  label: Text(
                    'Back to Forgot Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isBusy
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF374151),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnackBarContent extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SnackBarContent({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}