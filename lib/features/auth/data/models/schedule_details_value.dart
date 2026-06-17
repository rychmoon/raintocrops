class ScheduleDetailsValue {
  final List<String> selectedDays;
  final String note;
  final bool notificationsEnabled;
  final String createdBy;

  const ScheduleDetailsValue({
    required this.selectedDays,
    required this.note,
    required this.notificationsEnabled,
    required this.createdBy,
  });
}