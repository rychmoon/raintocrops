import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:raintocrops/core/widgets/app_snackbar.dart';
import 'package:raintocrops/features/irrigation/controller/irrigation_controller.dart';
import 'package:raintocrops/features/roles/controller/device_session_controller.dart';
import 'package:raintocrops/features/roles/service/device_service.dart';

class ConnectDeviceDialog extends StatefulWidget {
  const ConnectDeviceDialog({super.key});

  @override
  State<ConnectDeviceDialog> createState() => _ConnectDeviceDialogState();
}

class _ConnectDeviceDialogState extends State<ConnectDeviceDialog> {
  static const int _codeLength = 5;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  final DeviceService _deviceService = DeviceService();

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _enteredCode =>
      _controllers.map((controller) => controller.text).join();

  bool get _isCodeComplete =>
      _controllers.every((controller) => controller.text.trim().isNotEmpty);

  void _setDigit(int index, String value) {
    _controllers[index].value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _clearError() {
    if (_errorText != null && mounted) {
      setState(() => _errorText = null);
    }
  }

  void _onCodeChanged(String value, int index) {
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanValue.length > 1) {
      for (int i = 0; i < _codeLength; i++) {
        _setDigit(i, i < cleanValue.length ? cleanValue[i] : '');
      }

      final targetIndex = cleanValue.length >= _codeLength
          ? _codeLength - 1
          : cleanValue.length;

      if (cleanValue.length >= _codeLength) {
        _focusNodes[_codeLength - 1].unfocus();
      } else {
        _focusNodes[targetIndex].requestFocus();
      }

      if (_errorText != null) {
        _errorText = null;
      }

      if (mounted) setState(() {});
      return;
    }

    _setDigit(index, cleanValue);

    if (cleanValue.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    if (_errorText != null) {
      _errorText = null;
    }

    if (mounted) setState(() {});
  }

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final currentText = _controllers[index].text;

      if (currentText.isNotEmpty) {
        _setDigit(index, '');
        _clearError();
        if (mounted) setState(() {});
        return KeyEventResult.handled;
      }

      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
        _setDigit(index - 1, '');
        _clearError();
        if (mounted) setState(() {});
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index > 0) {
      _focusNodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _connect() async {
    if (!_isCodeComplete || _isSubmitting) return;

    final code = _enteredCode.trim();
    final sessionController = context.read<DeviceSessionController>();
    final irrigationController = context.read<IrrigationController>();
    final navigator = Navigator.of(context);
    final messengerContext = context;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final meta = await _deviceService.getPairingMeta(code);

      if (meta == null) {
        throw Exception('Invalid device code or device is offline.');
      }

      final result = await _deviceService.connectToDevice(
        code: code,
        mqttMeta: meta,
      );

      await sessionController.setSession(
        code: result.pairCode,
        linkedDeviceId: result.deviceId,
        linkedRole: result.role,
      );

      await irrigationController.bindDevice(result.deviceId);
      irrigationController.setPermission(
        result.role == 'owner' || result.role == 'controller',
      );

      if (!mounted) return;

      navigator.pop({
        'code': result.pairCode,
        'deviceId': result.deviceId,
        'role': result.role,
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!messengerContext.mounted) return;

        AppSnackbar.show(
          messengerContext,
          message: result.role == 'owner'
              ? 'Device linked successfully. You are now the owner.'
              : result.role == 'controller'
              ? 'Device linked successfully. You now have controller access.'
              : 'Device linked successfully. You are now a viewer.',
          type: AppSnackType.success,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Widget _buildCodeBox(int index, double boxWidth) {
    final hasError = _errorText != null;

    return SizedBox(
      width: boxWidth,
      height: 60,
      child: Focus(
        onKeyEvent: (_, event) => _handleKeyEvent(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          autofocus: index == 0,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: index == _codeLength - 1
              ? TextInputAction.done
              : TextInputAction.next,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) => _onCodeChanged(value, index),
          onTap: () {
            _controllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controllers[index].text.length,
            );
          },
          onSubmitted: (_) {
            if (index == _codeLength - 1 && _isCodeComplete) {
              _connect();
            } else if (index < _codeLength - 1) {
              _focusNodes[index + 1].requestFocus();
            }
          },
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFF87171)
                    : const Color(0xFFE5E7EB),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF38BDF8),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double gap = 8;
            final totalGap = gap * (_codeLength - 1);
            final boxWidth = (constraints.maxWidth - totalGap) / _codeLength;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: _isSubmitting
                      ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF38BDF8),
                      ),
                    ),
                  )
                      : const Icon(
                    Icons.memory_rounded,
                    size: 38,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Connect device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your device’s 5-digit code to begin secure pairing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_codeLength, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == _codeLength - 1 ? 0 : gap,
                      ),
                      child: _buildCodeBox(index, boxWidth),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _errorText != null
                      ? Text(
                    _errorText!,
                    key: const ValueKey('error'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                      : Text(
                    _isCodeComplete
                        ? 'Code entered: $_enteredCode'
                        : 'Please complete the 5-digit code.',
                    key: const ValueKey('hint'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _cancel,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                          (_isCodeComplete && !_isSubmitting) ? _connect : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            disabledBackgroundColor: const Color(0xFFBAE6FD),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            _isSubmitting ? 'Connecting...' : 'Connect',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}