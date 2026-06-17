import 'package:flutter/foundation.dart';

import '/features/irrigation/models/notify_model.dart';
import 'package:raintocrops/core/notification/service/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final List<NotifyModel> _items = [];
  final Map<String, DateTime> _lastShownAt = {};

  static const int _maxItems = 100;

  List<NotifyModel> get items => List.unmodifiable(_items);

  int get count => _items.length;
  int get unreadCount => _items.where((e) => !e.isRead).length;
  bool get hasNotifications => _items.isNotEmpty;

  List<NotifyModel> itemsForDevice(String? deviceId) {
    if (deviceId == null || deviceId.trim().isEmpty) return const [];
    return _items.where((item) => item.id == deviceId).toList();
  }

  int countForDevice(String? deviceId) {
    return itemsForDevice(deviceId).length;
  }

  int unreadCountForDevice(String? deviceId) {
    return itemsForDevice(deviceId).where((e) => !e.isRead).length;
  }

  bool hasNotificationsForDevice(String? deviceId) {
    return itemsForDevice(deviceId).isNotEmpty;
  }

  String _buildKey(NotifyModel notify) {
    return '${notify.id}_${notify.code}_${notify.message}_${notify.level}';
  }

  Duration _cooldownFor(NotifyModel notify) {
    switch (notify.level.toLowerCase()) {
      case 'critical':
        return const Duration(minutes: 1);
      case 'warning':
        return const Duration(minutes: 3);
      default:
        return const Duration(minutes: 5);
    }
  }

  void _trimIfNeeded() {
    if (_items.length > _maxItems) {
      _items.removeRange(_maxItems, _items.length);
    }

    if (_lastShownAt.length > 300) {
      final validKeys = _items.map(_buildKey).toSet();
      _lastShownAt.removeWhere((key, _) => !validKeys.contains(key));
    }
  }

  Future<void> handleIncomingPayload(Map<String, dynamic> payload) async {
    try {
      final notify = NotifyModel.fromJson(payload);

      if (notify.id.trim().isEmpty) return;
      if (notify.code.trim().isEmpty && notify.message.trim().isEmpty) return;

      final dedupeKey = _buildKey(notify);
      final now = DateTime.now();
      final cooldown = _cooldownFor(notify);
      final lastShown = _lastShownAt[dedupeKey];

      // block only within cooldown
      if (lastShown != null && now.difference(lastShown) < cooldown) {
        return;
      }

      _lastShownAt[dedupeKey] = now;

      // allow same notification to appear again after cooldown
      _items.insert(0, notify);
      _trimIfNeeded();
      notifyListeners();

      await AppNotificationService.instance.showNotify(
        id: '${dedupeKey}_${now.millisecondsSinceEpoch}'.hashCode.toString(),
        title: notify.title,
        body: notify.displayMessage,
        level: notify.level,
      );
    } catch (e) {
      debugPrint('Notification parse error: $e');
    }
  }

  void addSystemNotification({
    required String deviceId,
    required String code,
    required String title,
    required String message,
    String level = 'info',
    bool showLocalPush = false,
  }) {
    final notify = NotifyModel(
      id: deviceId,
      code: code,
      message: message,
      level: level,
      ts: DateTime.now().millisecondsSinceEpoch,
      receivedAt: DateTime.now(),
    );

    final dedupeKey = _buildKey(notify);
    final now = DateTime.now();
    final cooldown = _cooldownFor(notify);
    final lastShown = _lastShownAt[dedupeKey];

    if (lastShown != null && now.difference(lastShown) < cooldown) {
      return;
    }

    _lastShownAt[dedupeKey] = now;

    _items.insert(0, notify);
    _trimIfNeeded();
    notifyListeners();

    if (showLocalPush) {
      AppNotificationService.instance.showNotify(
        id: '${dedupeKey}_${now.millisecondsSinceEpoch}'.hashCode.toString(),
        title: title,
        body: message,
        level: level,
      );
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void markAllAsReadForDevice(String? deviceId) {
    if (deviceId == null || deviceId.trim().isEmpty) return;

    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == deviceId) {
        _items[i] = _items[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  void markAsRead(NotifyModel item) {
    final index = _items.indexOf(item);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
  }

  void removeNotification(NotifyModel item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearForDevice(String deviceId) {
    _items.removeWhere((item) => item.id == deviceId);
    _lastShownAt.removeWhere((key, _) => key.startsWith('${deviceId}_'));
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _lastShownAt.clear();
    notifyListeners();
  }
}