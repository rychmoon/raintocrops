import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(
      settings: settings,
    );

    await _createChannels();
  }

  Future<void> _createChannels() async {
    const infoChannel = AndroidNotificationChannel(
      'info_channel',
      'Info Notifications',
      description: 'General system updates',
      importance: Importance.defaultImportance,
    );

    const warningChannel = AndroidNotificationChannel(
      'warning_channel',
      'Warning Notifications',
      description: 'Warnings from the device',
      importance: Importance.high,
    );

    const criticalChannel = AndroidNotificationChannel(
      'critical_channel',
      'Critical Notifications',
      description: 'Critical alerts from the device',
      importance: Importance.max,
    );

    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(infoChannel);
      await androidPlugin.createNotificationChannel(warningChannel);
      await androidPlugin.createNotificationChannel(criticalChannel);
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> showNotify({
    required String id,
    required String title,
    required String body,
    required String level,
  }) async {
    final channel = _mapChannel(level);

    final androidDetails = AndroidNotificationDetails(
      channel.$1,
      channel.$2,
      channelDescription: channel.$3,
      importance: channel.$4,
      priority: channel.$5,
      category: AndroidNotificationCategory.status,
      styleInformation: const BigTextStyleInformation(''),
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: id.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  (String, String, String, Importance, Priority) _mapChannel(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
      case 'error':
        return (
        'critical_channel',
        'Critical Notifications',
        'Critical alerts from the device',
        Importance.max,
        Priority.max,
        );
      case 'warn':
      case 'warning':
        return (
        'warning_channel',
        'Warning Notifications',
        'Warnings from the device',
        Importance.high,
        Priority.high,
        );
      default:
        return (
        'info_channel',
        'Info Notifications',
        'General system updates',
        Importance.defaultImportance,
        Priority.defaultPriority,
        );
    }
  }
}