import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceLinkResult {
  final String pairCode;
  final String deviceId;
  final String role;
  final bool isNewDevice;

  const DeviceLinkResult({
    required this.pairCode,
    required this.deviceId,
    required this.role,
    required this.isNewDevice,
  });
}

class DeviceService {
  DeviceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<Map<String, dynamic>?> getPairingMeta(String code) async {
    final doc = await _firestore.collection('pairing_codes').doc(code).get();

    if (!doc.exists) {
      throw Exception('Invalid device code or device is offline.');
    }

    final data = doc.data();
    if (data == null) {
      throw Exception('Device pairing data is empty.');
    }

    return data;
  }

  Future<DeviceLinkResult> connectToDevice({
    required String code,
    required Map<String, dynamic> mqttMeta,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final pairCode = code.trim();
    final uid = user.uid;

    final deviceId = (mqttMeta['deviceId'] ?? mqttMeta['id'] ?? '').toString();
    if (deviceId.isEmpty) {
      throw Exception('Device ID is missing.');
    }

    final deviceName = (mqttMeta['name'] ?? 'Rain-to-Crops ESP32').toString();
    final deviceType =
    (mqttMeta['type'] ?? 'esp32_irrigation_controller').toString();
    final online = mqttMeta['online'] == true;

    final deviceRef = _firestore.collection('devices').doc(pairCode);
    final memberRef = deviceRef.collection('members').doc(uid);
    final userRef = _firestore.collection('users').doc(uid);

    return _firestore.runTransaction((tx) async {
      final deviceSnap = await tx.get(deviceRef);
      final memberSnap = await tx.get(memberRef);

      if (!deviceSnap.exists) {
        tx.set(deviceRef, {
          'pairCode': pairCode,
          'deviceId': deviceId,
          'name': deviceName,
          'type': deviceType,
          'online': online,
          'ownerUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(memberRef, {
          'uid': uid,
          'role': 'owner',
          'status': 'active',
          'joinedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(
          userRef,
          {
            'connectedDeviceCode': pairCode,
            'allowedCodes': FieldValue.arrayUnion([pairCode]),
            'activeRoleByCode': {
              pairCode: 'owner',
            },
          },
          SetOptions(merge: true),
        );

        return DeviceLinkResult(
          pairCode: pairCode,
          deviceId: deviceId,
          role: 'owner',
          isNewDevice: true,
        );
      }

      final deviceData = deviceSnap.data()!;
      final existingDeviceId = (deviceData['deviceId'] ?? '').toString();

      if (existingDeviceId.isEmpty) {
        throw Exception('This device record is incomplete.');
      }

      if (!memberSnap.exists) {
        tx.set(memberRef, {
          'uid': uid,
          'role': 'viewer',
          'status': 'active',
          'joinedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(
          userRef,
          {
            'connectedDeviceCode': pairCode,
            'allowedCodes': FieldValue.arrayUnion([pairCode]),
            'activeRoleByCode': {
              pairCode: 'viewer',
            },
          },
          SetOptions(merge: true),
        );

        tx.update(deviceRef, {
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return DeviceLinkResult(
          pairCode: pairCode,
          deviceId: existingDeviceId,
          role: 'viewer',
          isNewDevice: false,
        );
      }

      final memberData = memberSnap.data()!;
      final currentRole = (memberData['role'] ?? 'viewer').toString();

      tx.set(
        userRef,
        {
          'connectedDeviceCode': pairCode,
          'allowedCodes': FieldValue.arrayUnion([pairCode]),
          'activeRoleByCode': {
            pairCode: currentRole,
          },
        },
        SetOptions(merge: true),
      );

      tx.update(deviceRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return DeviceLinkResult(
        pairCode: pairCode,
        deviceId: existingDeviceId,
        role: currentRole,
        isNewDevice: false,
      );
    });
  }

  Future<void> requestAccess({
    required String pairCode,
    String requestedRole = 'controller',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final uid = user.uid;
    final deviceRef = _firestore.collection('devices').doc(pairCode);
    final memberRef = deviceRef.collection('members').doc(uid);
    final requestRef = deviceRef.collection('accessRequests').doc(uid);

    await _firestore.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      final requestSnap = await tx.get(requestRef);

      if (!memberSnap.exists) {
        throw Exception('You must pair this device first.');
      }

      final memberData = memberSnap.data()!;
      final currentRole = (memberData['role'] ?? 'viewer').toString();

      if (currentRole == 'owner' || currentRole == 'controller') {
        throw Exception('You already have elevated access.');
      }

      if (requestSnap.exists) {
        final requestData = requestSnap.data()!;
        final status = (requestData['status'] ?? 'pending').toString();

        if (status == 'pending') {
          throw Exception('Your request is already pending.');
        }

        if (status == 'approved') {
          throw Exception('Your access was already approved.');
        }
      }

      tx.set(
        requestRef,
        {
          'uid': uid,
          'requestedRole': requestedRole,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'reviewedAt': null,
          'reviewedBy': null,
        },
        SetOptions(merge: true),
      );

      tx.update(deviceRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> approveAccess({
    required String pairCode,
    required String targetUid,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final ownerUid = user.uid;

    final deviceRef = _firestore.collection('devices').doc(pairCode);
    final ownerMemberRef = deviceRef.collection('members').doc(ownerUid);
    final targetMemberRef = deviceRef.collection('members').doc(targetUid);
    final requestRef = deviceRef.collection('accessRequests').doc(targetUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    await _firestore.runTransaction((tx) async {
      final ownerMemberSnap = await tx.get(ownerMemberRef);
      final requestSnap = await tx.get(requestRef);

      if (!ownerMemberSnap.exists) {
        throw Exception('Owner membership not found.');
      }

      final ownerRole =
      (ownerMemberSnap.data()!['role'] ?? 'viewer').toString();

      if (ownerRole != 'owner') {
        throw Exception('Only the owner can approve requests.');
      }

      if (!requestSnap.exists) {
        throw Exception('Access request not found.');
      }

      final requestData = requestSnap.data()!;
      final requestStatus = (requestData['status'] ?? 'pending').toString();

      if (requestStatus != 'pending') {
        throw Exception('This request was already reviewed.');
      }

      tx.set(
        targetMemberRef,
        {
          'uid': targetUid,
          'role': 'controller',
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        requestRef,
        {
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': ownerUid,
        },
        SetOptions(merge: true),
      );

      tx.set(
        targetUserRef,
        {
          'allowedCodes': FieldValue.arrayUnion([pairCode]),
          'activeRoleByCode': {
            pairCode: 'controller',
          },
        },
        SetOptions(merge: true),
      );

      tx.update(deviceRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectAccess({
    required String pairCode,
    required String targetUid,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final ownerUid = user.uid;

    final deviceRef = _firestore.collection('devices').doc(pairCode);
    final ownerMemberRef = deviceRef.collection('members').doc(ownerUid);
    final requestRef = deviceRef.collection('accessRequests').doc(targetUid);

    await _firestore.runTransaction((tx) async {
      final ownerMemberSnap = await tx.get(ownerMemberRef);
      final requestSnap = await tx.get(requestRef);

      if (!ownerMemberSnap.exists) {
        throw Exception('Owner membership not found.');
      }

      final ownerRole =
      (ownerMemberSnap.data()!['role'] ?? 'viewer').toString();

      if (ownerRole != 'owner') {
        throw Exception('Only the owner can reject requests.');
      }

      if (!requestSnap.exists) {
        throw Exception('Access request not found.');
      }

      final requestData = requestSnap.data()!;
      final requestStatus = (requestData['status'] ?? 'pending').toString();

      if (requestStatus != 'pending') {
        throw Exception('This request was already reviewed.');
      }

      tx.set(
        requestRef,
        {
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': ownerUid,
        },
        SetOptions(merge: true),
      );

      tx.update(deviceRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMyAccessRequest({
    required String pairCode,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    return _firestore
        .collection('devices')
        .doc(pairCode)
        .collection('accessRequests')
        .doc(user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingRequests({
    required String pairCode,
  }) {
    return _firestore
        .collection('devices')
        .doc(pairCode)
        .collection('accessRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchControllers({
    required String pairCode,
  }) {
    return _firestore
        .collection('devices')
        .doc(pairCode)
        .collection('members')
        .where('role', isEqualTo: 'controller')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Future<void> removeControllerAccess({
    required String pairCode,
    required String targetUid,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final ownerUid = user.uid;

    final deviceRef = _firestore.collection('devices').doc(pairCode);
    final ownerMemberRef = deviceRef.collection('members').doc(ownerUid);
    final targetMemberRef = deviceRef.collection('members').doc(targetUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);
    final requestRef = deviceRef.collection('accessRequests').doc(targetUid);

    await _firestore.runTransaction((tx) async {
      final ownerSnap = await tx.get(ownerMemberRef);
      final targetSnap = await tx.get(targetMemberRef);

      if (!ownerSnap.exists) {
        throw Exception('Owner membership not found.');
      }

      final ownerRole = (ownerSnap.data()!['role'] ?? 'viewer').toString();
      if (ownerRole != 'owner') {
        throw Exception('Only the owner can remove controller access.');
      }

      if (!targetSnap.exists) {
        throw Exception('Controller member not found.');
      }

      final targetRole = (targetSnap.data()!['role'] ?? 'viewer').toString();
      if (targetRole != 'controller') {
        throw Exception('This user is not a controller.');
      }

      tx.set(
        targetMemberRef,
        {
          'uid': targetUid,
          'role': 'viewer',
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        targetUserRef,
        {
          'activeRoleByCode': {
            pairCode: 'viewer',
          },
        },
        SetOptions(merge: true),
      );

      tx.set(
        requestRef,
        {
          'status': 'removed',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': ownerUid,
        },
        SetOptions(merge: true),
      );

      tx.update(deviceRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String> getMyRole({
    required String pairCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in first.');
    }

    final doc = await _firestore
        .collection('devices')
        .doc(pairCode)
        .collection('members')
        .doc(user.uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return 'viewer';
    }

    return (doc.data()!['role'] ?? 'viewer').toString();
  }

  Future<void> syncPairingMeta(Map<String, dynamic> meta) async {
    final code = (meta['pc'] ?? '').toString();
    if (code.isEmpty) return;

    await _firestore.collection('pairing_codes').doc(code).set({
      'pairCode': code,
      'deviceId': meta['id'],
      'name': meta['name'],
      'type': meta['type'],
      'online': meta['online'] ?? false,
      'rawMeta': meta,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}