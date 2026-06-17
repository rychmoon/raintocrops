class RainHistoryEntry {
  final String deviceId;
  final String dateKey;
  final int year;
  final int month;
  final int day;

  /// Existing metric you already use for usage chart
  final double collectedLiters;

  /// New metric for actual daily rain collected
  final double collectedRainLiters;

  final double flowLpm;
  final double tankLevel;
  final double tankVolume;
  final DateTime? updatedAt;

  const RainHistoryEntry({
    required this.deviceId,
    required this.dateKey,
    required this.year,
    required this.month,
    required this.day,
    required this.collectedLiters,
    required this.collectedRainLiters,
    required this.flowLpm,
    required this.tankLevel,
    required this.tankVolume,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'date': dateKey,
      'year': year,
      'month': month,
      'day': day,
      'collectedLiters': collectedLiters,
      'collectedRainLiters': collectedRainLiters,
      'flowLpm': flowLpm,
      'tankLevel': tankLevel,
      'tankVolume': tankVolume,
      'updatedAt': updatedAt,
    };
  }

  factory RainHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RainHistoryEntry(
      deviceId: map['deviceId'] ?? '',
      dateKey: map['date'] ?? '',
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      day: map['day'] ?? 0,
      collectedLiters: (map['collectedLiters'] as num?)?.toDouble() ?? 0.0,
      collectedRainLiters:
      (map['collectedRainLiters'] as num?)?.toDouble() ?? 0.0,
      flowLpm: (map['flowLpm'] as num?)?.toDouble() ?? 0.0,
      tankLevel: (map['tankLevel'] as num?)?.toDouble() ?? 0.0,
      tankVolume: (map['tankVolume'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt']?.toDate(),
    );
  }
}