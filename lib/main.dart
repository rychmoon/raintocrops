import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:raintocrops/firebase_options.dart';
import 'package:raintocrops/features/auth/app_startup_gate.dart';
import 'package:raintocrops/features/auth/data/services/google_auth.dart';
import 'package:raintocrops/core/theme/theme_notifier.dart';
import 'package:raintocrops/features/irrigation/controller/irrigation_controller.dart';
import 'package:raintocrops/core/mqtt/mqtt_service.dart';
import 'package:raintocrops/features/roles/controller/device_session_controller.dart';

import 'package:raintocrops/core/notification/service/notification_service.dart';
import 'package:raintocrops/core/notification/controller/notification_controller.dart';

// Network imports
import 'package:raintocrops/core/networks/network_controller.dart';
import 'package:raintocrops/core/networks/network_service.dart';
import 'package:raintocrops/core/networks/widgets/offline_banner.dart';
import 'package:raintocrops/core/networks/widgets/network_status_listener.dart'; // <-- add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppNotificationService.instance.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init network service early
  await NetworkService.instance.init();

  try {
    await GoogleAuthService.initialize();
  } catch (e) {
    debugPrint('GoogleAuthService.initialize() failed: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(),
        ),
        ChangeNotifierProvider<DeviceSessionController>(
          create: (_) => DeviceSessionController()..loadSavedSession(),
        ),

        ChangeNotifierProvider<NetworkController>(
          create: (_) => NetworkController()..init(),
        ),

        ChangeNotifierProxyProvider2<NotificationController,
            DeviceSessionController, IrrigationController>(
          create: (_) => IrrigationController(
            mqttService: MqttService(),
          ),
          update: (_, notificationController, session, irrigationController) {
            irrigationController ??= IrrigationController(
              mqttService: MqttService(),
            );

            irrigationController.setNotificationController(
              notificationController,
            );

            irrigationController.setPermission(session.canControl);

            final currentDeviceId = session.deviceId;
            if (currentDeviceId != null && currentDeviceId.isNotEmpty) {
              irrigationController.bindDevice(currentDeviceId);
            } else {
              irrigationController.disconnect();
            }

            return irrigationController;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Raintocrops App',
      themeMode: themeNotifier.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light().textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          primary: Colors.lightBlue,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.lightBlue, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          primary: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.lightBlue, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const NetworkStatusListener(
        child: AppShellWithOfflineBanner(),
      ),
    );
  }
}

class AppShellWithOfflineBanner extends StatelessWidget {
  const AppShellWithOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          OfflineBanner(),
          Expanded(child: AppStartupGate()),
        ],
      ),
    );
  }
}