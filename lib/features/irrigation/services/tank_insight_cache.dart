import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '/core/utils/tank_sustain_predictor.dart';

class CachedTankInsight {
  final double currentTankLiters;
  final double usableTankLiters;
  final double estimatedLitersPerDay;
  final double estimatedDaysLeft;
  final double estimatedScheduleRunsLeft;
  final double litersPer60Sec;
  final int activeScheduleCount;
  final DateTime savedAt;

  const CachedTankInsight({
    required this.currentTankLiters,
    required this.usableTankLiters,
    required this.estimatedLitersPerDay,
    required this.estimatedDaysLeft,
    required this.estimatedScheduleRunsLeft,
    required this.litersPer60Sec,
    required this.activeScheduleCount,
    required this.savedAt,
  });

  factory CachedTankInsight.fromPrediction(
      TankSustainPredictionResult prediction,
      ) {
    return CachedTankInsight(
      currentTankLiters: prediction.currentTankLiters,
      usableTankLiters: prediction.usableTankLiters,
      estimatedLitersPerDay: prediction.estimatedLitersPerDay,
      estimatedDaysLeft: prediction.estimatedDaysLeft,
      estimatedScheduleRunsLeft: prediction.estimatedScheduleRunsLeft,
      litersPer60Sec: prediction.litersPer60Sec,
      activeScheduleCount: prediction.activeScheduleCount,
      savedAt: DateTime.now(),
    );
  }

  bool get hasSchedule => activeScheduleCount > 0;

  bool get hasDailyUse => estimatedLitersPerDay > 0;

  String get daysLeftText {
    if (!hasDailyUse) return 'Not set';

    if (estimatedDaysLeft <= 0) return 'Low';
    if (estimatedDaysLeft < 1) return 'Less than 1 day';
    if (estimatedDaysLeft < 2) return 'About 1 day';

    return '${estimatedDaysLeft.toStringAsFixed(1)} days';
  }

  String get wateringLeftText {
    if (!hasSchedule) return 'No schedule';

    if (estimatedScheduleRunsLeft <= 0) {
      return 'Not enough data';
    }

    return '${estimatedScheduleRunsLeft.toStringAsFixed(0)} times';
  }

  String get savedTimeText {
    final difference = DateTime.now().difference(savedAt);

    if (difference.inMinutes < 1) {
      return 'Saved just now';
    }

    if (difference.inMinutes < 60) {
      return 'Saved ${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return 'Saved ${difference.inHours} hr ago';
    }

    return 'Saved ${difference.inDays} day(s) ago';
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTankLiters': currentTankLiters,
      'usableTankLiters': usableTankLiters,
      'estimatedLitersPerDay': estimatedLitersPerDay,
      'estimatedDaysLeft': estimatedDaysLeft,
      'estimatedScheduleRunsLeft': estimatedScheduleRunsLeft,
      'litersPer60Sec': litersPer60Sec,
      'activeScheduleCount': activeScheduleCount,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory CachedTankInsight.fromJson(Map<String, dynamic> json) {
    return CachedTankInsight(
      currentTankLiters: _toDouble(json['currentTankLiters']),
      usableTankLiters: _toDouble(json['usableTankLiters']),
      estimatedLitersPerDay: _toDouble(json['estimatedLitersPerDay']),
      estimatedDaysLeft: _toDouble(json['estimatedDaysLeft']),
      estimatedScheduleRunsLeft: _toDouble(
        json['estimatedScheduleRunsLeft'],
      ),
      litersPer60Sec: _toDouble(json['litersPer60Sec']),
      activeScheduleCount: _toInt(json['activeScheduleCount']),
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class TankInsightCacheService {
  static String _cacheKey(String deviceId) {
    return 'latest_tank_insight_cache_$deviceId';
  }

  static Future<void> saveFromPrediction({
    required String deviceId,
    required TankSustainPredictionResult prediction,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final cached = CachedTankInsight.fromPrediction(prediction);

    await prefs.setString(
      _cacheKey(deviceId),
      jsonEncode(cached.toJson()),
    );
  }

  static Future<CachedTankInsight?> loadLatest({
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_cacheKey(deviceId));

    if (rawData == null || rawData.isEmpty) return null;

    try {
      final decoded = jsonDecode(rawData);

      if (decoded is! Map<String, dynamic>) return null;

      return CachedTankInsight.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear({
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(deviceId));
  }
}