import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raintocrops/features/auth/data/models/irrigation_schedule.dart';

class IrrigationScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _deviceRef(String pairCode) {
    return _firestore.collection('devices').doc(pairCode);
  }

  CollectionReference<Map<String, dynamic>> _deviceSchedules(String pairCode) {
    return _deviceRef(pairCode).collection('schedules');
  }

  Future<String> _getMyRole(String pairCode) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final doc = await _firestore
        .collection('devices')
        .doc(pairCode)
        .collection('members')
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return 'viewer';
    }

    final data = doc.data()!;
    final status = (data['status'] ?? 'active').toString();
    final role = (data['role'] ?? 'viewer').toString();

    if (status != 'active') return 'viewer';
    return role;
  }

  Future<void> _ensureCanManage(String pairCode) async {
    final role = await _getMyRole(pairCode);
    if (role != 'owner' && role != 'controller') {
      throw Exception('Only owner or controller can manage schedules.');
    }
  }

  Future<void> _ensureCanView(String pairCode) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final doc = await _firestore
        .collection('devices')
        .doc(pairCode)
        .collection('members')
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('You do not have access to this device.');
    }

    final data = doc.data()!;
    final status = (data['status'] ?? 'active').toString();
    if (status != 'active') {
      throw Exception('Your access to this device is inactive.');
    }
  }

  Future<String> addSchedule({
    required String pairCode,
    required String note,
    required int hour,
    required int minute,
    required int duration,
    required List<String> selectedDays,
    required bool notificationsEnabled,
    required bool isActive,
    required String createdBy,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await _ensureCanManage(pairCode);

    final doc = await _deviceSchedules(pairCode).add({
      'note': note,
      'hour': hour,
      'minute': minute,
      'duration': duration,
      'selectedDays': selectedDays,
      'notificationsEnabled': notificationsEnabled,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'espScheduleId': null,
    });

    await _deviceRef(pairCode).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Stream<List<IrrigationScheduleModel>> getSchedules({
    required String pairCode,
  }) {
    return _deviceSchedules(pairCode)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IrrigationScheduleModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateSchedule({
    required String pairCode,
    required String scheduleId,
    required String note,
    required int hour,
    required int minute,
    required int duration,
    required List<String> selectedDays,
    required bool notificationsEnabled,
    required bool isActive,
    required String createdBy,
  }) async {
    await _ensureCanManage(pairCode);

    await _deviceSchedules(pairCode).doc(scheduleId).update({
      'note': note,
      'hour': hour,
      'minute': minute,
      'duration': duration,
      'selectedDays': selectedDays,
      'notificationsEnabled': notificationsEnabled,
      'isActive': isActive,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _deviceRef(pairCode).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateScheduleStatus({
    required String pairCode,
    required String scheduleId,
    required bool isActive,
  }) async {
    await _ensureCanManage(pairCode);

    await _deviceSchedules(pairCode).doc(scheduleId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _deviceRef(pairCode).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEspScheduleId({
    required String pairCode,
    required String scheduleId,
    required int espScheduleId,
  }) async {
    await _ensureCanManage(pairCode);

    await _deviceSchedules(pairCode).doc(scheduleId).update({
      'espScheduleId': espScheduleId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearEspScheduleId({
    required String pairCode,
    required String scheduleId,
  }) async {
    await _ensureCanManage(pairCode);

    await _deviceSchedules(pairCode).doc(scheduleId).update({
      'espScheduleId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSchedule({
    required String pairCode,
    required String scheduleId,
  }) async {
    await _ensureCanManage(pairCode);

    await _deviceSchedules(pairCode).doc(scheduleId).delete();

    await _deviceRef(pairCode).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<IrrigationScheduleModel?> getNearestSchedule({
    required String pairCode,
  }) {
    return _deviceSchedules(pairCode).snapshots().map((snapshot) {
      final schedules = snapshot.docs
          .map((doc) => IrrigationScheduleModel.fromMap(doc.data(), doc.id))
          .where((schedule) => schedule.isActive)
          .toList();

      if (schedules.isEmpty) return null;

      schedules.sort((a, b) {
        final aNext = _getNextOccurrence(a);
        final bNext = _getNextOccurrence(b);
        return aNext.compareTo(bNext);
      });

      return schedules.first;
    });
  }

  DateTime _getNextOccurrence(IrrigationScheduleModel schedule) {
    final now = DateTime.now();

    const dayMap = {
      'Sunday': DateTime.sunday,
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
    };

    DateTime? nearest;

    for (final day in schedule.selectedDays) {
      final targetWeekday = dayMap[day];
      if (targetWeekday == null) continue;

      int daysAhead = targetWeekday - now.weekday;
      if (daysAhead < 0) {
        daysAhead += 7;
      }

      DateTime candidate = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.hour,
        schedule.minute,
      ).add(Duration(days: daysAhead));

      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 7));
      }

      if (nearest == null || candidate.isBefore(nearest)) {
        nearest = candidate;
      }
    }

    return nearest ?? now.add(const Duration(days: 3650));
  }

  List<int> mapDaysToMqtt(List<String> selectedDays) {
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
        .where((value) => value >= 0)
        .toList();
  }

  String formatMqttTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}