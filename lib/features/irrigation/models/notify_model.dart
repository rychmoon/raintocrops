import 'package:flutter/material.dart';

class NotifyModel {
  final String id; // device id
  final String code;
  final String message;
  final String level; // info | warning | critical
  final int ts; // device millis() timestamp
  final DateTime receivedAt; // app receive timestamp
  final bool isRead;

  const NotifyModel({
    required this.id,
    required this.code,
    required this.message,
    required this.level,
    required this.ts,
    required this.receivedAt,
    this.isRead = false,
  });

  factory NotifyModel.fromJson(Map<String, dynamic> json) {
    return NotifyModel(
      id: (json['id'] ?? '').toString(),
      code: (json['c'] ?? '').toString(),
      message: (json['m'] ?? '').toString(),
      level: _normalizeLevel((json['l'] ?? 'info').toString()),
      ts: json['ts'] is int ? json['ts'] as int : int.tryParse('${json['ts']}') ?? 0,
      receivedAt: DateTime.now(),
    );
  }

  NotifyModel copyWith({
    String? id,
    String? code,
    String? message,
    String? level,
    int? ts,
    DateTime? receivedAt,
    bool? isRead,
  }) {
    return NotifyModel(
      id: id ?? this.id,
      code: code ?? this.code,
      message: message ?? this.message,
      level: level ?? this.level,
      ts: ts ?? this.ts,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  static String _normalizeLevel(String raw) {
    switch (raw.toLowerCase()) {
      case 'warn':
      case 'warning':
        return 'warning';
      case 'critical':
      case 'error':
        return 'critical';
      default:
        return 'info';
    }
  }

  String get title {
    switch (code.toLowerCase()) {
      case 'online':
        return 'Device is online';

    // New overflow notifications (v3)
      case 'overflow_pond':
        return 'Overflow routed to pond';
      case 'overflow_reserve':
        return 'Overflow routed to reserve';
      case 'overflow_stop':
        return 'Overflow stopped';

      case 'irrigation_start':
        return 'Irrigation started';
      case 'irrigation_stop':
        return 'Irrigation stopped';
      case 'irrigation_block':
        return 'Irrigation blocked';
      case 'irrigation_switch':
        return 'Irrigation source switched';

      case 'schedule_added':
        return 'Schedule added';
      case 'schedule_updated':
        return 'Schedule updated';
      case 'schedule_deleted':
        return 'Schedule deleted';
      case 'schedule_run':
        return 'Scheduled watering started';
      case 'schedule_clear_all':
        return 'Schedules cleared';
      case 'schedule_toggled':
        return 'Schedule toggled';
      case 'schedule_duplicate':
        return 'Duplicate schedule time';
      case 'schedule_not_found':
        return 'Schedule not found';
      case 'schedule_invalid':
        return 'Invalid schedule data';
      case 'schedule_full':
        return 'Schedule limit reached';
      case 'schedule_error':
        return 'Schedule error';

      case 'ph_dose_start':
        return 'Adding pH solution';
      case 'ph_dose_stop':
        return 'pH dosing stopped';
      case 'ph_bottle_empty':
        return 'pH bottle is empty';

      case 'auto_soil':
        return 'Auto soil changed';
      case 'relay_manual':
        return 'Manual control used';
      case 'relay_invalid':
        return 'Invalid relay target';
      case 'stop_all':
        return 'Everything stopped';
      case 'json_error':
        return 'Data error';
      case 'daily_reset':
        return 'Daily counter reset';

    // keep access group (if your backend sends these)
      case 'access_request':
        return 'New access request';
      case 'access_approved':
        return 'Access approved';
      case 'access_rejected':
        return 'Access rejected';
      case 'controller_removed':
        return 'Controller removed';

      default:
        switch (level) {
          case 'critical':
            return 'Critical alert';
          case 'warning':
            return 'Warning';
          default:
            return 'Notification';
        }
    }
  }

  String get category {
    switch (code.toLowerCase()) {
      case 'overflow_pond':
      case 'overflow_reserve':
      case 'overflow_stop':
        return 'Water';

      case 'irrigation_start':
      case 'irrigation_stop':
      case 'irrigation_block':
      case 'irrigation_switch':
      case 'auto_soil':
        return 'Irrigation';

      case 'schedule_added':
      case 'schedule_updated':
      case 'schedule_deleted':
      case 'schedule_run':
      case 'schedule_clear_all':
      case 'schedule_toggled':
      case 'schedule_duplicate':
      case 'schedule_not_found':
      case 'schedule_invalid':
      case 'schedule_full':
      case 'schedule_error':
        return 'Schedule';

      case 'ph_dose_start':
      case 'ph_dose_stop':
      case 'ph_bottle_empty':
        return 'pH';

      case 'access_request':
      case 'access_approved':
      case 'access_rejected':
      case 'controller_removed':
        return 'Access';

      case 'online':
      case 'json_error':
      case 'stop_all':
      case 'relay_invalid':
      case 'relay_manual':
        return 'System';

      default:
        return 'General';
    }
  }

  IconData get icon {
    switch (code.toLowerCase()) {
      case 'overflow_pond':
      case 'overflow_reserve':
      case 'overflow_stop':
        return Icons.water_damage_outlined;

      case 'irrigation_start':
      case 'irrigation_stop':
      case 'irrigation_block':
      case 'auto_soil':
        return Icons.grass_outlined;
      case 'irrigation_switch':
        return Icons.swap_horiz_rounded;

      case 'schedule_added':
      case 'schedule_updated':
      case 'schedule_deleted':
      case 'schedule_run':
      case 'schedule_clear_all':
      case 'schedule_toggled':
        return Icons.schedule_outlined;
      case 'schedule_duplicate':
      case 'schedule_not_found':
      case 'schedule_invalid':
      case 'schedule_full':
      case 'schedule_error':
        return Icons.schedule_send_outlined;

      case 'ph_dose_start':
      case 'ph_dose_stop':
      case 'ph_bottle_empty':
        return Icons.science_outlined;

      case 'access_request':
        return Icons.admin_panel_settings_outlined;
      case 'access_approved':
        return Icons.verified_rounded;
      case 'access_rejected':
        return Icons.cancel_outlined;
      case 'controller_removed':
        return Icons.person_remove_alt_1_rounded;

      case 'json_error':
        return Icons.wifi_off_rounded;
      case 'online':
        return Icons.sensors_outlined;
      case 'relay_invalid':
        return Icons.toggle_off_outlined;
      case 'relay_manual':
        return Icons.tune_rounded;
      case 'stop_all':
        return Icons.power_settings_new_rounded;

      default:
        switch (level) {
          case 'critical':
            return Icons.error_outline_rounded;
          case 'warning':
            return Icons.warning_amber_rounded;
          default:
            return Icons.notifications_none_rounded;
        }
    }
  }

  Color get accentColor {
    switch (code.toLowerCase()) {
      case 'access_approved':
        return const Color(0xFF16A34A);
      case 'access_rejected':
      case 'controller_removed':
      case 'ph_bottle_empty':
      case 'schedule_error':
      case 'json_error':
        return const Color(0xFFDC2626);
      case 'access_request':
      case 'overflow_pond':
      case 'overflow_reserve':
      case 'overflow_stop':
        return const Color(0xFF2563EB);
      case 'schedule_duplicate':
      case 'schedule_invalid':
      case 'schedule_full':
      case 'irrigation_block':
      case 'relay_invalid':
        return const Color(0xFFD97706);
    }

    switch (level) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'warning':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF0284C7);
    }
  }

  String get displayMessage {
    switch (code.toLowerCase()) {
      case 'online':
        return 'Your device is now connected and ready.';

    // v3 overflow messages
      case 'overflow_pond':
        return message.trim().isNotEmpty
            ? message
            : 'Excess water is being routed to the pond.';
      case 'overflow_reserve':
        return message.trim().isNotEmpty
            ? message
            : 'Excess water is being routed to the reserve container.';
      case 'overflow_stop':
        return message.trim().isNotEmpty
            ? message
            : 'Overflow routing has stopped.';

      case 'irrigation_start':
        return 'The watering process is now running.';
      case 'irrigation_stop':
        return 'The watering process has stopped.';
      case 'irrigation_block':
        return 'Watering could not start because no valid water source is available.';
      case 'irrigation_switch':
        return message.trim().isNotEmpty
            ? message
            : 'Irrigation source was switched automatically.';

      case 'schedule_added':
        return 'A new watering schedule was added.';
      case 'schedule_updated':
        return 'The watering schedule was updated.';
      case 'schedule_deleted':
        return 'The watering schedule was removed.';
      case 'schedule_run':
        return 'A saved watering schedule is now running.';
      case 'schedule_clear_all':
        return 'All saved watering schedules were removed.';
      case 'schedule_toggled':
        return 'A watering schedule was enabled or disabled.';
      case 'schedule_duplicate':
        return 'Another schedule already uses that time.';
      case 'schedule_not_found':
        return 'The selected schedule could not be found.';
      case 'schedule_invalid':
        return 'Schedule data is invalid. Please check time/days.';
      case 'schedule_full':
        return 'Maximum number of schedules reached.';
      case 'schedule_error':
        return 'The schedule operation failed. Try again.';

      case 'ph_dose_start':
        return 'The system started adding pH solution.';
      case 'ph_dose_stop':
        return 'The system stopped adding pH solution for now.';
      case 'ph_bottle_empty':
        return 'The pH bottle is empty. Please refill it.';

      case 'auto_soil':
        return 'The auto soil setting was changed.';
      case 'relay_manual':
        return message.trim().isNotEmpty
            ? message
            : 'A manual control action was used on the device.';
      case 'relay_invalid':
        return 'The relay target sent from app is invalid.';
      case 'stop_all':
        return 'All running outputs were turned off.';
      case 'json_error':
        return 'The device received invalid data.';
      case 'daily_reset':
        return 'The daily collected water counter was reset.';

      case 'access_request':
      case 'access_approved':
      case 'access_rejected':
      case 'controller_removed':
        return message.trim().isNotEmpty ? message : 'Access update available.';

      default:
        return message.trim().isNotEmpty ? message : 'No more details available.';
    }
  }

  String get relativeTime {
    final diff = DateTime.now().difference(receivedAt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}