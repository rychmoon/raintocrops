import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceMemberModel {
  final String uid;
  final String role; // owner | viewer | controller
  final String status; // active
  final Timestamp joinedAt;

  const DeviceMemberModel({
    required this.uid,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  factory DeviceMemberModel.fromMap(Map<String, dynamic> data, String uid) {
    return DeviceMemberModel(
      uid: uid,
      role: (data['role'] as String?) ?? 'viewer',
      status: (data['status'] as String?) ?? 'active',
      joinedAt: data['joinedAt'] is Timestamp
          ? data['joinedAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'status': status,
      'joinedAt': joinedAt,
    };
  }

  bool get isOwner => role == 'owner' && status == 'active';
  bool get isViewer => role == 'viewer' && status == 'active';
  bool get isController => role == 'controller' && status == 'active';
}