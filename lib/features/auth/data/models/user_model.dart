import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // optional app-level role only
  final List<String> allowedCodes;
  final List<String> providers;
  final Timestamp createdAt;
  final String? photoUrl;
  final String? googlePhotoUrl;
  final bool hideGooglePhoto;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role = 'viewer',
    this.allowedCodes = const [],
    this.providers = const ['password'],
    this.photoUrl,
    this.googlePhotoUrl,
    this.hideGooglePhoto = false,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'viewer',
      allowedCodes: List<String>.from(data['allowedCodes'] ?? const []),
      providers: List<String>.from(data['providers'] ?? const ['password']),
      photoUrl: data['photoUrl'] as String?,
      googlePhotoUrl: data['googlePhotoUrl'] as String?,
      hideGooglePhoto: data['hideGooglePhoto'] as bool? ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    List<String>? allowedCodes,
    List<String>? providers,
    Timestamp? createdAt,
    String? photoUrl,
    String? googlePhotoUrl,
    bool? hideGooglePhoto,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      allowedCodes: List<String>.from(allowedCodes ?? this.allowedCodes),
      providers: List<String>.from(providers ?? this.providers),
      photoUrl: photoUrl ?? this.photoUrl,
      googlePhotoUrl: googlePhotoUrl ?? this.googlePhotoUrl,
      hideGooglePhoto: hideGooglePhoto ?? this.hideGooglePhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'allowedCodes': allowedCodes,
      'providers': providers,
      'photoUrl': photoUrl,
      'googlePhotoUrl': googlePhotoUrl,
      'hideGooglePhoto': hideGooglePhoto,
      'createdAt': createdAt,
    };
  }

  String get initials {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final value = '$first$last'.trim();

    if (value.isNotEmpty) return value.toUpperCase();
    if (email.trim().isNotEmpty) return email.trim()[0].toUpperCase();

    return '?';
  }
}