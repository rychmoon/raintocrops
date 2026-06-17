import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '/features/presentation/home/widgets/current_weather_skeleton.dart';
import '/features/presentation/home/widgets/current_weather_card.dart';
import 'appbar/welcome_app_bar.dart';
import '/features/presentation/home/widgets/today_forecast_card.dart';
import '/features/presentation/home/widgets/today_forecast_skeleton.dart';
import '/features/presentation/home/widgets/connected_devices_card.dart';
import '/features/weather_api/controllers/weather_controller.dart';
import '/features/auth/data/models/user_model.dart';
import '/features/presentation/home/widgets/connect_device_dialog.dart';
import '/features/roles/controller/device_session_controller.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToForecast;

  const HomeScreen({
    super.key,
    this.onGoToForecast,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherController _weatherController = WeatherController();

  static const double _defaultLat = 14.652464980022662;
  static const double _defaultLon = 121.04927315875439;

  @override
  void initState() {
    super.initState();
    _weatherController.fetchWeather(
      lat: _defaultLat,
      lon: _defaultLon,
    );
  }

  @override
  void dispose() {
    _weatherController.dispose();
    super.dispose();
  }

  Future<void> _showConnectDeviceDialog() async {

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) => const ConnectDeviceDialog(),
    );

    if (!mounted || result == null) return;

    final code = result['code']?.toString();
    final deviceId = result['deviceId']?.toString();
    final role = result['role']?.toString() ?? 'viewer';

    if (code == null || code.isEmpty || deviceId == null || deviceId.isEmpty) {
      return;
    }

    debugPrint('Paired code: $code');
    debugPrint('Device ID: $deviceId');
    debugPrint('Role: $role');

    debugPrint('Paired code: $code');
    debugPrint('Device ID: $deviceId');
    debugPrint('Role: $role');
  }

  Future<void> _copyCodeToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Device code copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _showPairCodeDialog(String code) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device code',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use this code when you want to connect another account to this device.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () async {
                    await _copyCodeToClipboard(code);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 15,
                              color: Color(0xFF6B7280),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tap to copy',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final session = context.watch<DeviceSessionController>();

    final bool hasPairedDevice =
        session.pairedCode != null && session.pairedCode!.trim().isNotEmpty;

    final bool isConnected =
        session.deviceId != null && session.deviceId!.trim().isNotEmpty;

    if (firebaseUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F6F6),
        body: Center(
          child: Text(
            'User not logged in',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Failed to load user data',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  'No user data found',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final doc = snapshot.data!;

            if (!doc.exists || doc.data() == null) {
              return const Center(
                child: Text(
                  'User data not found',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final userModel = UserModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );

            return AnimatedBuilder(
              animation: _weatherController,
              builder: (context, _) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WelcomeAppBar(user: userModel),
                      const SizedBox(height: 20),

                      _buildWeatherSection(),
                      const SizedBox(height: 20),

                      _buildTodayForecastSection(),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _SectionHeader(
                              title: !hasPairedDevice
                                  ? 'Connect your device'
                                  : isConnected
                                  ? 'Device connected'
                                  : 'Device paired',
                              subtitle: !hasPairedDevice
                                  ? 'Pair your ESP32 to start monitoring your field'
                                  : isConnected
                                  ? 'Your field is currently being monitored'
                                  : 'Waiting for your ESP32 to send live updates',
                            ),
                          ),
                          if (hasPairedDevice)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _showPairCodeDialog(session.pairedCode!);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 24),
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: const Color(0xFF374151),
                                  ),
                                  child: const Text(
                                    'View code',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isConnected
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isConnected
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFF59E0B))
                                                .withValues(alpha: 0.22),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isConnected ? 'Live' : 'Waiting',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isConnected
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            InkWell(
                              onTap: _showConnectDeviceDialog,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.20), // light blue shadow
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 21,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const ConnectedDevicesCard(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _weatherController.isLoading
          ? const CurrentWeatherCardSkeleton(
        key: ValueKey('weather_loading'),
      )
          : _weatherController.errorMessage != null
          ? _WeatherErrorCard(
        key: const ValueKey('weather_error'),
        message: _weatherController.errorMessage!,
      )
          : _weatherController.weather != null
          ? CurrentWeatherCard(
        key: const ValueKey('weather_data'),
        currentWeather: _weatherController.weather!.currentWeather,
        airPollution: _weatherController.weather!.airPollution,
      )
          : const SizedBox.shrink(
        key: ValueKey('weather_empty'),
      ),
    );
  }

  Widget _buildTodayForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Today',
                subtitle: 'Rain possible later',
              ),
            ),
            TextButton(
              onPressed: () {
                widget.onGoToForecast?.call();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next 5 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Iconsax.arrow_right_3_outline,
                    size: 12,
                    color: Colors.lightBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _weatherController.isLoading
              ? const TodayForecastSkeleton(
            key: ValueKey('forecast_loading'),
          )
              : _weatherController.weather != null
              ? TodayForecastCard(
            key: const ValueKey('forecast_data'),
            forecast: _weatherController.weather!.forecast,
          )
              : const SizedBox.shrink(
            key: ValueKey('forecast_empty'),
          ),
        ),
      ],
    );
  }
}

class _WeatherErrorCard extends StatelessWidget {
  final String message;

  const _WeatherErrorCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}