import 'package:flutter/material.dart';

class ScheduleFormData {
  final TimeOfDay selectedTime;
  final List<String> selectedDays;
  final String note;
  final bool notificationsEnabled;
  final String createdBy;

  const ScheduleFormData({
    required this.selectedTime,
    required this.selectedDays,
    required this.note,
    required this.notificationsEnabled,
    required this.createdBy,
  });

  factory ScheduleFormData.initial() {
    return const ScheduleFormData(
      selectedTime: TimeOfDay(hour: 8, minute: 0),
      selectedDays: [],
      note: '',
      notificationsEnabled: true,
      createdBy: '',
    );
  }

  ScheduleFormData copyWith({
    TimeOfDay? selectedTime,
    List<String>? selectedDays,
    String? note,
    bool? notificationsEnabled,
    String? createdBy,
  }) {
    return ScheduleFormData(
      selectedTime: selectedTime ?? this.selectedTime,
      selectedDays: selectedDays ?? this.selectedDays,
      note: note ?? this.note,
      notificationsEnabled:
      notificationsEnabled ?? this.notificationsEnabled,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': selectedTime.hour,
      'minute': selectedTime.minute,
      'selectedDays': selectedDays,
      'note': note,
      'notificationsEnabled': notificationsEnabled,
      'createdBy': createdBy,
    };
  }

  @override
  String toString() {
    final hh = selectedTime.hour.toString().padLeft(2, '0');
    final mm = selectedTime.minute.toString().padLeft(2, '0');

    return '''
ScheduleFormData(
  selectedTime: $hh:$mm,
  selectedDays: $selectedDays,
  note: $note,
  notificationsEnabled: $notificationsEnabled,
  createdBy: $createdBy
)
''';
  }
}