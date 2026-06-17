class ScheduleItemModel {
  final int id;
  final bool enabled;
  final String time; // HH:MM
  final int duration; // seconds
  final List<int> days; // 0=Sun ... 6=Sat

  const ScheduleItemModel({
    required this.id,
    required this.enabled,
    required this.time,
    required this.duration,
    required this.days,
  });

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'on') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    }
    return fallback;
  }

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['d'] as List?) ?? const [];

    return ScheduleItemModel(
      id: _asInt(json['id']),
      enabled: _asBool(json['en']),
      time: (json['t'] ?? '00:00').toString(),
      duration: _asInt(json['dur']),
      days: rawDays.map((e) => _asInt(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'en': enabled,
      't': time,
      'dur': duration,
      'd': days,
    };
  }
}

class ScheduleStateModel {
  final String deviceId; // id
  final String pairingCode; // pc
  final int count;
  final List<ScheduleItemModel> items;

  const ScheduleStateModel({
    required this.deviceId,
    required this.pairingCode,
    required this.count,
    required this.items,
  });

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory ScheduleStateModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];

    final parsedItems = rawItems
        .map((e) => ScheduleItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ScheduleStateModel(
      deviceId: (json['id'] ?? '').toString(),
      pairingCode: (json['pc'] ?? '').toString(),
      count: _asInt(json['count'], fallback: parsedItems.length),
      items: parsedItems,
    );
  }

  factory ScheduleStateModel.empty() {
    return const ScheduleStateModel(
      deviceId: '',
      pairingCode: '',
      count: 0,
      items: [],
    );
  }
}