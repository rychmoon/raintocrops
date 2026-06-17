import '/features/irrigation/models/telemetry_model.dart';

class TankScheduleUsageInput {
  final int durationSec;
  final bool active;
  final List<int> days;

  const TankScheduleUsageInput({
    required this.durationSec,
    required this.active,
    required this.days,
  });

  int get runsPerWeek {
    if (!active) return 0;
    return days.toSet().length;
  }
}

class TankSustainPredictionResult {
  final double currentTankLiters;
  final double usableTankLiters;

  final double litersPer60Sec;
  final double litersPerSecond;

  final int activeScheduleCount;
  final int totalRunsPerWeek;

  final double scheduleLitersPerDay;
  final double autoSoilLitersPerDay;
  final double estimatedLitersPerDay;
  final double estimatedLitersPerWeek;

  final double averageLitersPerScheduleRun;
  final double estimatedScheduleRunsLeft;
  final double estimatedDaysLeft;

  final String title;
  final String subtitle;
  final String confidence;
  final String explanation;

  const TankSustainPredictionResult({
    required this.currentTankLiters,
    required this.usableTankLiters,
    required this.litersPer60Sec,
    required this.litersPerSecond,
    required this.activeScheduleCount,
    required this.totalRunsPerWeek,
    required this.scheduleLitersPerDay,
    required this.autoSoilLitersPerDay,
    required this.estimatedLitersPerDay,
    required this.estimatedLitersPerWeek,
    required this.averageLitersPerScheduleRun,
    required this.estimatedScheduleRunsLeft,
    required this.estimatedDaysLeft,
    required this.title,
    required this.subtitle,
    required this.confidence,
    required this.explanation,
  });

  bool get hasUsablePrediction {
    return usableTankLiters > 0 && estimatedLitersPerDay > 0;
  }
}

class TankSustainPredictor {
  /// Your tested calibration:
  /// 60 seconds = 3.5L to 4L.
  /// Average = 3.75L.
  static const double defaultLitersPer60Sec = 3.00;

  static double getLitersPerSecond(double litersPer60Sec) {
    if (litersPer60Sec <= 0) return 0.0;
    return litersPer60Sec / 60.0;
  }

  static TankSustainPredictionResult predict({
    required TelemetryModel telemetry,
    required List<TankScheduleUsageInput> schedules,

    /// Calibration from your actual test.
    double litersPer60Sec = defaultLitersPer60Sec,

    /// Reserve amount that should not be counted as usable water.
    double reserveLiters = 20.0,

    /// Include possible auto-soil watering in estimate.
    bool includeAutoSoilEstimate = true,

    /// Your ESP auto-soil currently starts with 60 seconds.
    int autoSoilDurationSec = 60,

    /// Because auto-soil is not time-based, estimate how often it may run
    /// when soil is DRY.
    double estimatedAutoSoilRunsPerDayWhenDry = 1.0,
  }) {
    final double currentTankLiters = telemetry.volume;

    final double usableTankLiters =
    (currentTankLiters - reserveLiters)
        .clamp(0.0, double.infinity)
        .toDouble();

    final double lps = getLitersPerSecond(litersPer60Sec);

    final activeSchedules = schedules.where((schedule) {
      return schedule.active &&
          schedule.durationSec > 0 &&
          schedule.days.isNotEmpty;
    }).toList();

    double scheduleLitersPerWeek = 0.0;
    int totalRunsPerWeek = 0;

    for (final schedule in activeSchedules) {
      final int adjustedDurationSec = _adjustDurationByWeather(
        originalDurationSec: schedule.durationSec,
        telemetry: telemetry,
        source: 'schedule',
      );

      final double litersPerRun = adjustedDurationSec * lps;
      final int runsPerWeek = schedule.runsPerWeek;

      scheduleLitersPerWeek += litersPerRun * runsPerWeek;
      totalRunsPerWeek += runsPerWeek;
    }

    final double scheduleLitersPerDay = scheduleLitersPerWeek / 7.0;

    double autoSoilLitersPerDay = 0.0;

    if (includeAutoSoilEstimate) {
      final String soil = telemetry.soilStatus.toUpperCase();

      if (soil == 'DRY') {
        final int adjustedAutoSoilSec = _adjustDurationByWeather(
          originalDurationSec: autoSoilDurationSec,
          telemetry: telemetry,
          source: 'auto_soil',
        );

        autoSoilLitersPerDay =
            adjustedAutoSoilSec * lps * estimatedAutoSoilRunsPerDayWhenDry;
      }
    }

    final double estimatedLitersPerDay =
        scheduleLitersPerDay + autoSoilLitersPerDay;

    final double estimatedLitersPerWeek = estimatedLitersPerDay * 7.0;

    final double averageLitersPerScheduleRun = totalRunsPerWeek <= 0
        ? 0.0
        : scheduleLitersPerWeek / totalRunsPerWeek;

    final double estimatedScheduleRunsLeft =
    averageLitersPerScheduleRun <= 0
        ? 0.0
        : usableTankLiters / averageLitersPerScheduleRun;

    final double estimatedDaysLeft = estimatedLitersPerDay <= 0
        ? 0.0
        : usableTankLiters / estimatedLitersPerDay;

    final String title = _buildTitle(
      usableTankLiters: usableTankLiters,
      estimatedLitersPerDay: estimatedLitersPerDay,
      estimatedDaysLeft: estimatedDaysLeft,
    );

    final String subtitle = _buildSubtitle(
      activeScheduleCount: activeSchedules.length,
      totalRunsPerWeek: totalRunsPerWeek,
      estimatedLitersPerDay: estimatedLitersPerDay,
    );

    final String confidence = _buildConfidence(
      telemetry: telemetry,
      activeScheduleCount: activeSchedules.length,
      estimatedLitersPerDay: estimatedLitersPerDay,
    );

    final String explanation = _buildExplanation(
      telemetry: telemetry,
      litersPer60Sec: litersPer60Sec,
      reserveLiters: reserveLiters,
      scheduleLitersPerDay: scheduleLitersPerDay,
      autoSoilLitersPerDay: autoSoilLitersPerDay,
      estimatedLitersPerDay: estimatedLitersPerDay,
      activeScheduleCount: activeSchedules.length,
      totalRunsPerWeek: totalRunsPerWeek,
    );

    return TankSustainPredictionResult(
      currentTankLiters: currentTankLiters,
      usableTankLiters: usableTankLiters,
      litersPer60Sec: litersPer60Sec,
      litersPerSecond: lps,
      activeScheduleCount: activeSchedules.length,
      totalRunsPerWeek: totalRunsPerWeek,
      scheduleLitersPerDay: scheduleLitersPerDay,
      autoSoilLitersPerDay: autoSoilLitersPerDay,
      estimatedLitersPerDay: estimatedLitersPerDay,
      estimatedLitersPerWeek: estimatedLitersPerWeek,
      averageLitersPerScheduleRun: averageLitersPerScheduleRun,
      estimatedScheduleRunsLeft: estimatedScheduleRunsLeft,
      estimatedDaysLeft: estimatedDaysLeft,
      title: title,
      subtitle: subtitle,
      confidence: confidence,
      explanation: explanation,
    );
  }

  static int _adjustDurationByWeather({
    required int originalDurationSec,
    required TelemetryModel telemetry,
    required String source,
  }) {
    if (originalDurationSec <= 0) return 0;

    final String action = source == 'auto_soil'
        ? telemetry.wxad.toUpperCase()
        : telemetry.wxsd.toUpperCase();

    final int shortenedSec = source == 'auto_soil'
        ? telemetry.wxas.round()
        : telemetry.wxss.round();

    if (action == 'SKIP' || action == 'DELAY') {
      return 0;
    }

    if (action == 'SHORTEN') {
      if (shortenedSec > 0) {
        return shortenedSec.clamp(0, originalDurationSec).toInt();
      }

      return (originalDurationSec * 0.5).round();
    }

    /// If irrigation is currently running and ESP already reports
    /// actual applied duration, use it as a hint only when the source matches.
    final String currentSource = telemetry.source.toLowerCase();
    final String targetSource = source.toLowerCase();

    if (currentSource == targetSource && telemetry.appliedIrrigationSec > 0) {
      return telemetry.appliedIrrigationSec
          .clamp(0, originalDurationSec)
          .toInt();
    }

    return originalDurationSec;
  }

  static String _buildTitle({
    required double usableTankLiters,
    required double estimatedLitersPerDay,
    required double estimatedDaysLeft,
  }) {
    if (usableTankLiters <= 0) {
      return 'Tank has no usable water';
    }

    if (estimatedLitersPerDay <= 0) {
      return 'No watering expected for now';
    }

    if (estimatedDaysLeft < 1) {
      return 'Less than 1 day left';
    }

    if (estimatedDaysLeft < 2) {
      return 'About 1 day left';
    }

    return 'About ${estimatedDaysLeft.toStringAsFixed(1)} days left';
  }

  static String _buildSubtitle({
    required int activeScheduleCount,
    required int totalRunsPerWeek,
    required double estimatedLitersPerDay,
  }) {
    if (activeScheduleCount <= 0) {
      return 'No active schedule is currently included.';
    }

    return '$activeScheduleCount active schedule(s), '
        '$totalRunsPerWeek run(s)/week, '
        'about ${estimatedLitersPerDay.toStringAsFixed(1)}L/day.';
  }

  static String _buildConfidence({
    required TelemetryModel telemetry,
    required int activeScheduleCount,
    required double estimatedLitersPerDay,
  }) {
    if (telemetry.tankStatus.toUpperCase() == 'UNKNOWN') {
      return 'Low';
    }

    if (telemetry.volume <= 0) {
      return 'Low';
    }

    if (activeScheduleCount <= 0 &&
        telemetry.soilStatus.toUpperCase() != 'DRY') {
      return 'Low';
    }

    if (estimatedLitersPerDay <= 0) {
      return 'Medium';
    }

    if (telemetry.wxst || !telemetry.wxok) {
      return 'Medium';
    }

    return 'High';
  }

  static String _buildExplanation({
    required TelemetryModel telemetry,
    required double litersPer60Sec,
    required double reserveLiters,
    required double scheduleLitersPerDay,
    required double autoSoilLitersPerDay,
    required double estimatedLitersPerDay,
    required int activeScheduleCount,
    required int totalRunsPerWeek,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      'Based on ${litersPer60Sec.toStringAsFixed(2)}L per 60 seconds from your pump test. ',
    );

    if (activeScheduleCount > 0) {
      buffer.write(
        'Your active schedules create $totalRunsPerWeek run(s) per week and may use around ${scheduleLitersPerDay.toStringAsFixed(1)}L/day. ',
      );
    } else {
      buffer.write('No active schedule is currently counted. ');
    }

    if (autoSoilLitersPerDay > 0) {
      buffer.write(
        'Auto-soil may add around ${autoSoilLitersPerDay.toStringAsFixed(1)}L/day because the soil is currently dry. ',
      );
    }

    if (reserveLiters > 0) {
      buffer.write(
        '${reserveLiters.toStringAsFixed(0)}L is reserved and not counted as usable water. ',
      );
    }

    final String scheduleDecision = telemetry.wxsd.toUpperCase();
    final String autoDecision = telemetry.wxad.toUpperCase();

    if (scheduleDecision == 'SHORTEN' || autoDecision == 'SHORTEN') {
      buffer.write('Weather adjustment may shorten watering duration. ');
    }

    if (scheduleDecision == 'SKIP' || autoDecision == 'SKIP') {
      buffer.write('Some watering may be skipped because of rain. ');
    }

    if (scheduleDecision == 'DELAY' || autoDecision == 'DELAY') {
      buffer.write('Some watering may be delayed because rain is expected. ');
    }

    buffer.write(
      'Estimated total use is ${estimatedLitersPerDay.toStringAsFixed(1)}L/day.',
    );

    return buffer.toString();
  }
}