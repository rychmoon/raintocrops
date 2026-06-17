import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceAccessRequestModel {
  final String uid;
  final String status; // pending | approved | rejected
  final Timestamp requestedAt;

  const DeviceAccessRequestModel({
    required this.uid,
    required this.status,
    required this.requestedAt,
  });

  factory DeviceAccessRequestModel.fromMap(
      Map<String, dynamic> data,
      String uid,
      ) {
    return DeviceAccessRequestModel(
      uid: uid,
      status: (data['status'] as String?) ?? 'pending',
      requestedAt: data['requestedAt'] is Timestamp
          ? data['requestedAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'status': status,
      'requestedAt': requestedAt,
    };
  }
}