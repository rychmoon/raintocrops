import 'package:cloud_firestore/cloud_firestore.dart';

class IrrigationScheduleModel {
  final String id;
  final String note;
  final int hour;
  final int minute;
  final int duration; // seconds
  final List<String> selectedDays;
  final bool notificationsEnabled;
  final bool isActive;
  final String createdBy;
  final Timestamp? createdAt;
  final int? espScheduleId;

  IrrigationScheduleModel({
    required this.id,
    required this.note,
    required this.hour,
    required this.minute,
    required this.duration,
    required this.selectedDays,
    required this.notificationsEnabled,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.espScheduleId,
  });

  bool get isEveryday => selectedDays.length == 7;

  factory IrrigationScheduleModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return IrrigationScheduleModel(
      id: id,
      note: (map['note'] ?? '') as String,
      hour: (map['hour'] ?? 0) as int,
      minute: (map['minute'] ?? 0) as int,
      duration: (map['duration'] ?? 300) as int,
      selectedDays: (map['selectedDays'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      notificationsEnabled: (map['notificationsEnabled'] ?? true) as bool,
      isActive: (map['isActive'] ?? true) as bool,
      createdBy: (map['createdBy'] ?? '') as String,
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] as Timestamp : null,
      espScheduleId: map['espScheduleId'] is int ? map['espScheduleId'] as int : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note': note,
      'hour': hour,
      'minute': minute,
      'duration': duration,
      'selectedDays': selectedDays,
      'notificationsEnabled': notificationsEnabled,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'espScheduleId': espScheduleId,
    };
  }

  List<int> get mqttDays {
    return selectedDays
        .map((day) {
      switch (day) {
        case 'Sunday':
          return 0;
        case 'Monday':
          return 1;
        case 'Tuesday':
          return 2;
        case 'Wednesday':
          return 3;
        case 'Thursday':
          return 4;
        case 'Friday':
          return 5;
        case 'Saturday':
          return 6;
        default:
          return -1;
      }
    })
        .where((e) => e >= 0)
        .toList();
  }

  String get mqttTime {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Map<String, dynamic> toAddScheduleJson() {
    return {
      'action': 'add',
      'time': mqttTime,
      'duration': duration,
      'days': mqttDays,
      'active': isActive,
    };
  }

  Map<String, dynamic> toEditScheduleJson({
    required int scheduleItemId,
  }) {
    return {
      'action': 'edit',
      'id': scheduleItemId,
      'time': mqttTime,
      'duration': duration,
      'days': mqttDays,
      'active': isActive,
    };
  }

  Map<String, dynamic> toToggleScheduleJson({
    required int scheduleItemId,
    required bool active,
  }) {
    return {
      'action': 'toggle',
      'id': scheduleItemId,
      'active': active,
    };
  }

  Map<String, dynamic> toDeleteScheduleJson({
    required int scheduleItemId,
  }) {
    return {
      'action': 'delete',
      'id': scheduleItemId,
    };
  }

  IrrigationScheduleModel copyWith({
    String? id,
    String? note,
    int? hour,
    int? minute,
    int? duration,
    List<String>? selectedDays,
    bool? notificationsEnabled,
    bool? isActive,
    String? createdBy,
    Timestamp? createdAt,
    int? espScheduleId,
  }) {
    return IrrigationScheduleModel(
      id: id ?? this.id,
      note: note ?? this.note,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      duration: duration ?? this.duration,
      selectedDays: selectedDays ?? this.selectedDays,
      notificationsEnabled:
      notificationsEnabled ?? this.notificationsEnabled,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      espScheduleId: espScheduleId ?? this.espScheduleId,
    );
  }
}

class ScheduleItemModel {
  final int id;
  final bool enabled;
  final String time;
  final int duration;
  final List<int> days;

  const ScheduleItemModel({
    required this.id,
    required this.enabled,
    required this.time,
    required this.duration,
    required this.days,
  });

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleItemModel(
      id: (json['id'] ?? 0) as int,
      enabled: (json['en'] ?? false) as bool,
      time: (json['t'] ?? '00:00') as String,
      duration: (json['dur'] ?? 0) as int,
      days: List<int>.from(json['d'] ?? const []),
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
  final String deviceId;
  final String pairingCode;
  final int count;
  final List<ScheduleItemModel> items;

  const ScheduleStateModel({
    required this.deviceId,
    required this.pairingCode,
    required this.count,
    required this.items,
  });

  factory ScheduleStateModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];

    return ScheduleStateModel(
      deviceId: (json['id'] ?? '') as String,
      pairingCode: (json['pc'] ?? '') as String,
      count: (json['count'] ?? 0) as int,
      items: rawItems
          .map((e) => ScheduleItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
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