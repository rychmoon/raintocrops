import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  final String code;
  final String? ownerUid;
  final String name;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const DeviceModel({
    required this.code,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.ownerUid,
  });

  factory DeviceModel.fromMap(Map<String, dynamic> data, String docId) {
    return DeviceModel(
      code: docId,
      ownerUid: data['ownerUid'] as String?,
      name: (data['name'] as String?) ?? 'My Device',
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'ownerUid': ownerUid,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}