import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSessionController extends ChangeNotifier {
  String? pairedCode;
  String? deviceId;
  String? role;
  bool isLoading = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSub;

  bool get isPaired => pairedCode != null && deviceId != null;
  bool get isOwner => role == 'owner';
  bool get isViewer => role == 'viewer';
  bool get isController => role == 'controller';
  bool get canControl => role == 'owner' || role == 'controller';

  String? _key(String suffix, {String? uidOverride}) {
    final uid = uidOverride ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return 'device_session_${uid}_$suffix';
  }

  Future<void> loadSavedSession() async {
    isLoading = true;
    notifyListeners();

    try {
      final codeKey = _key('code');
      final deviceIdKey = _key('device_id');
      final roleKey = _key('role');

      if (codeKey == null || deviceIdKey == null || roleKey == null) {
        pairedCode = null;
        deviceId = null;
        role = null;
        await _cancelRoleSubscription();
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      pairedCode = prefs.getString(codeKey);
      deviceId = prefs.getString(deviceIdKey);
      role = prefs.getString(roleKey);

      if (pairedCode != null && pairedCode!.isNotEmpty) {
        await refreshRoleFromFirestore();
        await _listenToRoleChanges();
      } else {
        await _cancelRoleSubscription();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSession({
    required String code,
    required String linkedDeviceId,
    required String linkedRole,
  }) async {
    final codeKey = _key('code');
    final deviceIdKey = _key('device_id');
    final roleKey = _key('role');

    if (codeKey == null || deviceIdKey == null || roleKey == null) return;

    pairedCode = code;
    deviceId = linkedDeviceId;
    role = linkedRole;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(codeKey, code);
    await prefs.setString(deviceIdKey, linkedDeviceId);
    await prefs.setString(roleKey, linkedRole);

    await _listenToRoleChanges();
    notifyListeners();
  }

  Future<void> updateRoleOnly(String newRole) async {
    final roleKey = _key('role');
    if (roleKey == null) return;

    role = newRole;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(roleKey, newRole);

    notifyListeners();
  }

  Future<void> refreshRoleFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = pairedCode;
    final roleKey = _key('role');

    if (uid == null || code == null || code.isEmpty || roleKey == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(code)
        .collection('members')
        .doc(uid)
        .get();

    final latestRole = _extractRoleFromMemberDoc(doc);

    role = latestRole;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(roleKey, latestRole);

    notifyListeners();
  }

  String _extractRoleFromMemberDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    if (!doc.exists || doc.data() == null) {
      return 'viewer';
    }

    final data = doc.data()!;
    final status = (data['status'] ?? 'active').toString();
    final memberRole = (data['role'] ?? 'viewer').toString();

    if (status != 'active') {
      return 'viewer';
    }

    return memberRole;
  }

  Future<void> _listenToRoleChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = pairedCode;
    final roleKey = _key('role');

    if (uid == null || code == null || code.isEmpty || roleKey == null) {
      await _cancelRoleSubscription();
      return;
    }

    await _cancelRoleSubscription();

    _roleSub = FirebaseFirestore.instance
        .collection('devices')
        .doc(code)
        .collection('members')
        .doc(uid)
        .snapshots()
        .listen((doc) async {
      final latestRole = _extractRoleFromMemberDoc(doc);

      if (role == latestRole) return;

      role = latestRole;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(roleKey, latestRole);

      notifyListeners();
    });
  }

  Future<void> _cancelRoleSubscription() async {
    final sub = _roleSub;
    _roleSub = null;
    await sub?.cancel();
  }

  Future<void> clearSession({String? uidOverride}) async {
    final prefs = await SharedPreferences.getInstance();

    final effectiveUid = uidOverride ?? FirebaseAuth.instance.currentUser?.uid;

    final codeKey = _key('code', uidOverride: effectiveUid);
    final deviceIdKey = _key('device_id', uidOverride: effectiveUid);
    final roleKey = _key('role', uidOverride: effectiveUid);

    await _cancelRoleSubscription();

    if (codeKey != null) await prefs.remove(codeKey);
    if (deviceIdKey != null) await prefs.remove(deviceIdKey);
    if (roleKey != null) await prefs.remove(roleKey);

    pairedCode = null;
    deviceId = null;
    role = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    super.dispose();
  }
}