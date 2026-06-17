import 'package:cloud_firestore/cloud_firestore.dart';

import '/features/collected_rain_statistics/rain_history_entry.dart';
import '/features/irrigation/models/telemetry_model.dart';

class RainHistoryService {
  RainHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> saveDailyTelemetry({
    required String deviceId,
    required TelemetryModel telemetry,
    DateTime? now,
  }) async {
    final localNow = now ?? DateTime.now();
    final dateKey = _dateKey(localNow);

    final docRef = _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('rainHistory')
        .doc(dateKey);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data() ?? <String, dynamic>{};

      // Keep your old behavior for usage
      final usageLiters = telemetry.collected;

      // New accurate daily collected logic (based on tank volume increase)
      final previousVolume =
          (data['lastTankVolume'] as num?)?.toDouble() ?? telemetry.volume;
      final volumeDelta = telemetry.volume - previousVolume;
      final addedByRain = volumeDelta > 0 ? volumeDelta : 0.0;

      final previousCollectedRain =
          (data['collectedRainLiters'] as num?)?.toDouble() ?? 0.0;
      final collectedRainLiters = previousCollectedRain + addedByRain;

      final entry = RainHistoryEntry(
        deviceId: deviceId,
        dateKey: dateKey,
        year: localNow.year,
        month: localNow.month,
        day: localNow.day,
        collectedLiters: usageLiters, // unchanged metric
        collectedRainLiters: collectedRainLiters, // new metric
        flowLpm: telemetry.flow,
        tankLevel: telemetry.level,
        tankVolume: telemetry.volume,
        updatedAt: localNow,
      );

      tx.set(
        docRef,
        {
          ...entry.toMap(),
          'lastTankVolume': telemetry.volume, // helper field for next delta calc
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<List<RainHistoryEntry>> fetchDailyHistory({
    required String deviceId,
    int limit = 400,
  }) async {
    final snap = await _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('rainHistory')
        .orderBy('date', descending: false)
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => RainHistoryEntry.fromMap(doc.data()))
        .toList();
  }
}