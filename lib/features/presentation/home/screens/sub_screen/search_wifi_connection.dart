import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '/features/irrigation/controller/irrigation_controller.dart';

class SearchWiFiConnection extends StatefulWidget {
  const SearchWiFiConnection({super.key});

  @override
  State<SearchWiFiConnection> createState() => _SearchWiFiConnectionState();
}

class _SearchWiFiConnectionState extends State<SearchWiFiConnection> {
  static const Color _lightBlue = Colors.lightBlue;
  static const Color _bgColor = Color(0xFFF6F8FB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGray = Color(0xFF6B7280);
  static const Color _softGray = Color(0xFFF3F6FA);

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _ssidFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  List<WiFiAccessPoint> _wifiList = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? _scanSubscription;

  bool _isScanning = false;
  bool _isPasswordVisible = false;
  bool _showManualInput = false;

  String? _selectedSSID;
  String _statusMessage = 'Ready to scan nearby WiFi.';
  String? _scanDebugMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToScanResults();
      _scanWifi();
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scrollController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _ssidFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _listenToScanResults() async {
    final can = await WiFiScan.instance.canGetScannedResults(
      askPermissions: true,
    );

    if (can != CanGetScannedResults.yes) {
      if (!mounted) return;
      setState(() {
        _scanDebugMessage = 'Scan result listener not ready: ${can.name}';
      });
      return;
    }

    _scanSubscription = WiFiScan.instance.onScannedResultsAvailable.listen(
          (results) {
        if (!mounted) return;

        final cleaned = _cleanAndSortWifiList(results);

        setState(() {
          _wifiList = cleaned;

          if (cleaned.isNotEmpty) {
            _statusMessage = 'Select your WiFi network.';
            _scanDebugMessage = null;
          }
        });
      },
    );
  }

  Future<void> _scanWifi() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Searching nearby WiFi...';
      _scanDebugMessage = null;
    });

    final canStart = await WiFiScan.instance.canStartScan(
      askPermissions: true,
    );

    if (canStart != CanStartScan.yes) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _statusMessage = _messageForCanStartScan(canStart);
        _scanDebugMessage = 'Scan check result: ${canStart.name}';
        _showManualInput = true;
      });

      _scrollToConnectionCard();
      return;
    }

    final started = await WiFiScan.instance.startScan();

    if (!started) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _statusMessage =
        'Scan did not start. Try again later or type the WiFi name manually.';
        _scanDebugMessage = 'startScan returned false';
        _showManualInput = true;
      });

      _scrollToConnectionCard();
      return;
    }

    await Future.delayed(const Duration(seconds: 2));

    final canGet = await WiFiScan.instance.canGetScannedResults(
      askPermissions: true,
    );

    if (canGet != CanGetScannedResults.yes) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _statusMessage = _messageForCanGetResults(canGet);
        _scanDebugMessage = 'Get results check: ${canGet.name}';
        _showManualInput = true;
      });

      _scrollToConnectionCard();
      return;
    }

    final results = await WiFiScan.instance.getScannedResults();
    final cleaned = _cleanAndSortWifiList(results);

    if (!mounted) return;

    setState(() {
      _wifiList = cleaned;
      _isScanning = false;

      if (_wifiList.isEmpty) {
        _statusMessage =
        'No WiFi found. Make sure WiFi and Location are ON, then scan again.';
        _scanDebugMessage =
        'Scan completed but returned 0 visible networks. You can type the WiFi name manually.';
        _showManualInput = true;
      } else {
        _statusMessage = 'Select your WiFi network.';
        _scanDebugMessage = null;
      }
    });

    if (_wifiList.isEmpty) {
      _scrollToConnectionCard();
    }
  }

  String _messageForCanStartScan(CanStartScan result) {
    switch (result) {
      case CanStartScan.notSupported:
        return 'WiFi scanning is not supported on this device.';
      case CanStartScan.noLocationPermissionRequired:
        return 'Location permission is required. Please allow Location permission.';
      case CanStartScan.noLocationPermissionDenied:
        return 'Location permission is denied. Please enable it in app settings.';
      case CanStartScan.noLocationPermissionUpgradeAccuracy:
        return 'Please allow precise location for WiFi scanning.';
      case CanStartScan.noLocationServiceDisabled:
        return 'Location/GPS is OFF. Turn ON phone Location, then scan again.';
      case CanStartScan.failed:
        return 'WiFi scan failed. Try again or type the WiFi name manually.';
      case CanStartScan.yes:
        return 'Ready to scan nearby WiFi.';
    }
  }

  String _messageForCanGetResults(CanGetScannedResults result) {
    switch (result) {
      case CanGetScannedResults.notSupported:
        return 'Getting WiFi results is not supported on this device.';
      case CanGetScannedResults.noLocationPermissionRequired:
        return 'Location permission is required to show WiFi results.';
      case CanGetScannedResults.noLocationPermissionDenied:
        return 'Location permission is denied. Please enable it in app settings.';
      case CanGetScannedResults.noLocationPermissionUpgradeAccuracy:
        return 'Please allow precise location to show WiFi results.';
      case CanGetScannedResults.noLocationServiceDisabled:
        return 'Location/GPS is OFF. Turn ON phone Location, then scan again.';
      case CanGetScannedResults.yes:
        return 'Select your WiFi network.';
    }
  }

  List<WiFiAccessPoint> _cleanAndSortWifiList(List<WiFiAccessPoint> results) {
    final Map<String, WiFiAccessPoint> bestSignalBySsid = {};

    for (final wifi in results) {
      final ssid = wifi.ssid.trim();

      if (ssid.isEmpty) continue;

      final existing = bestSignalBySsid[ssid];

      if (existing == null || wifi.level > existing.level) {
        bestSignalBySsid[ssid] = wifi;
      }
    }

    final list = bestSignalBySsid.values.toList();
    list.sort((a, b) => b.level.compareTo(a.level));

    return list;
  }

  void _selectWifi(WiFiAccessPoint wifi) {
    final ssid = wifi.ssid.trim();

    setState(() {
      _selectedSSID = ssid;
      _ssidController.text = ssid;
      _passwordController.clear();
      _isPasswordVisible = false;
      _showManualInput = true;
      _statusMessage = 'Enter the password for $ssid.';
    });

    _scrollToConnectionCard();
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _passwordFocusNode.requestFocus();
    });
  }

  void _useManualInput() {
    setState(() {
      _showManualInput = true;
      _selectedSSID = null;
      _ssidController.clear();
      _passwordController.clear();
      _statusMessage = 'Type your WiFi name and password manually.';
    });

    _scrollToConnectionCard();
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _ssidFocusNode.requestFocus();
    });
  }

  void _scrollToConnectionCard() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _sendWifiToESP() {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      _showSnackBar('Please select or type a WiFi name.');
      return;
    }

    if (ssid.length > 32) {
      _showSnackBar('WiFi name is too long. Maximum is 32 characters.');
      return;
    }

    if (password.isNotEmpty && password.length < 8) {
      _showSnackBar('Password must be at least 8 characters.');
      return;
    }

    FocusScope.of(context).unfocus();

    context.read<IrrigationController>().updateWiFiCredentials(
      ssid: ssid,
      password: password,
    );

    _showSnackBar('WiFi details sent to device: $ssid');

    setState(() {
      _statusMessage = 'Updating ESP32 WiFi to $ssid...';
    });
  }

  void _revertToDefaultWifi() {
    FocusScope.of(context).unfocus();

    context.read<IrrigationController>().updateWiFiCredentials(
      ssid: '',
      password: '',
    );

    _showSnackBar('Device will return to default WiFi.');

    setState(() {
      _selectedSSID = null;
      _ssidController.clear();
      _passwordController.clear();
      _statusMessage = 'Default WiFi command sent to ESP32.';
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  IconData _signalIcon(int level) {
    if (level >= -55) return Icons.wifi;
    if (level >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  String _signalText(int level) {
    if (level >= -55) return 'Strong';
    if (level >= -70) return 'Good';
    return 'Weak';
  }

  bool _isSecured(WiFiAccessPoint wifi) {
    final caps = wifi.capabilities.toUpperCase();
    return caps.contains('WPA') || caps.contains('WEP');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IrrigationController>();
    final canSend = controller.canControl && controller.isConnected;
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textDark),
        title: const Text(
          'WiFi Connection',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _HeaderCard(
                isConnected: controller.isConnected,
                canControl: controller.canControl,
                statusMessage: _statusMessage,
                debugMessage: _scanDebugMessage,
                onRefresh: _scanWifi,
                onManual: _useManualInput,
                isScanning: _isScanning,
              ),
            ),

            if (_wifiList.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyWifiState(
                  isScanning: _isScanning,
                  onRefresh: _scanWifi,
                  onManual: _useManualInput,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final wifi = _wifiList[index];
                      final isSelected = _selectedSSID == wifi.ssid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WifiTile(
                          wifi: wifi,
                          isSelected: isSelected,
                          signalIcon: _signalIcon(wifi.level),
                          signalText: _signalText(wifi.level),
                          secured: _isSecured(wifi),
                          onTap: () => _selectWifi(wifi),
                        ),
                      );
                    },
                    childCount: _wifiList.length,
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showManualInput
                    ? _ConnectionCard(
                  ssidController: _ssidController,
                  passwordController: _passwordController,
                  ssidFocusNode: _ssidFocusNode,
                  passwordFocusNode: _passwordFocusNode,
                  isPasswordVisible: _isPasswordVisible,
                  canSend: canSend,
                  hasSelectedWifi: _selectedSSID != null,
                  onTogglePassword: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  onSend: _sendWifiToESP,
                  onUseDefault: _revertToDefaultWifi,
                )
                    : const SizedBox.shrink(),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: keyboardBottom + 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isConnected,
    required this.canControl,
    required this.statusMessage,
    required this.debugMessage,
    required this.onRefresh,
    required this.onManual,
    required this.isScanning,
  });

  final bool isConnected;
  final bool canControl;
  final String statusMessage;
  final String? debugMessage;
  final VoidCallback onRefresh;
  final VoidCallback onManual;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final bool ready = isConnected && canControl;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.lightBlue.withValues(alpha: 0.95),
            Colors.lightBlueAccent.withValues(alpha: 0.80),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.lightBlue.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.router_rounded,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 10),
          const Text(
            'Update Device WiFi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            ready
                ? 'Choose a nearby WiFi or type the WiFi name manually.'
                : 'Connect to your device first before sending WiFi details.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (debugMessage != null) ...[
            const SizedBox(height: 5),
            Text(
              debugMessage!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isScanning ? null : onRefresh,
                  icon: isScanning
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.lightBlue,
                    ),
                  )
                      : const Icon(Icons.refresh_rounded, size: 17),
                  label: Text(isScanning ? 'Scanning' : 'Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.lightBlue,
                    disabledBackgroundColor:
                    Colors.white.withValues(alpha: 0.75),
                    disabledForegroundColor: Colors.lightBlue,
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManual,
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: const Text('Manual'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WifiTile extends StatelessWidget {
  const _WifiTile({
    required this.wifi,
    required this.isSelected,
    required this.signalIcon,
    required this.signalText,
    required this.secured,
    required this.onTap,
  });

  final WiFiAccessPoint wifi;
  final bool isSelected;
  final IconData signalIcon;
  final String signalText;
  final bool secured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.lightBlue.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? Colors.lightBlue : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  signalIcon,
                  color: Colors.lightBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wifi.ssid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          signalText,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 7),
                        if (secured)
                          const Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.lightBlue,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWifiState extends StatelessWidget {
  const _EmptyWifiState({
    required this.isScanning,
    required this.onRefresh,
    required this.onManual,
  });

  final bool isScanning;
  final VoidCallback onRefresh;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        children: [
          Icon(
            isScanning ? Icons.wifi_find_rounded : Icons.wifi_off_rounded,
            size: 48,
            color: Colors.lightBlue,
          ),
          const SizedBox(height: 12),
          Text(
            isScanning ? 'Searching WiFi nearby...' : 'No WiFi found',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Turn ON phone Location/GPS and WiFi. You can also type the WiFi name manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManual,
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: const Text('Type Manually'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    side: const BorderSide(color: Colors.lightBlue),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isScanning ? null : onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Scan Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    Colors.lightBlue.withValues(alpha: 0.35),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.ssidController,
    required this.passwordController,
    required this.ssidFocusNode,
    required this.passwordFocusNode,
    required this.isPasswordVisible,
    required this.canSend,
    required this.hasSelectedWifi,
    required this.onTogglePassword,
    required this.onSend,
    required this.onUseDefault,
  });

  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final FocusNode ssidFocusNode;
  final FocusNode passwordFocusNode;
  final bool isPasswordVisible;
  final bool canSend;
  final bool hasSelectedWifi;
  final VoidCallback onTogglePassword;
  final VoidCallback onSend;
  final VoidCallback onUseDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('connection-card'),
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.settings_input_antenna_rounded,
                  color: Colors.lightBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Details',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'These details will be sent to your ESP32 device.',
                      style: TextStyle(
                        color: Color(0xFF8A94A6),
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ModernTextField(
            controller: ssidController,
            focusNode: ssidFocusNode,
            label: 'WiFi Name',
            hint: 'Example: HOMOFIBR2G',
            icon: Icons.wifi_rounded,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 9),

          _ModernTextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            label: 'Password',
            hint: 'Leave empty only for open WiFi',
            icon: Icons.lock_rounded,
            obscureText: !isPasswordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSend(),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              splashRadius: 18,
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: const Color(0xFF9CA3AF),
                size: 19,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  canSend ? Icons.info_outline_rounded : Icons.warning_rounded,
                  color: canSend ? Colors.lightBlue : const Color(0xFFF59E0B),
                  size: 16,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    canSend
                        ? 'Your phone will not switch networks. The app only sends this WiFi to the device.'
                        : 'Connect to your device first before saving WiFi details.',
                    style: const TextStyle(
                      color: Color(0xFF7B8494),
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: canSend ? onUseDefault : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    disabledForegroundColor:
                    Colors.lightBlue.withValues(alpha: 0.35),
                    side: BorderSide(
                      color: canSend
                          ? Colors.lightBlue
                          : Colors.lightBlue.withValues(alpha: 0.25),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Use Default'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: canSend ? onSend : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    Colors.lightBlue.withValues(alpha: 0.35),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(hasSelectedWifi ? 'Send WiFi' : 'Save WiFi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFF7B8494),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFB5BDCA),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.lightBlue,
          size: 19,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 40,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF3F6FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE8EDF4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.lightBlue,
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}