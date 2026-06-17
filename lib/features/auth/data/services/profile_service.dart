import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ProfileService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Get current user data from Firestore
  static Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Get current active role based on connected device code
  static Future<String> getCurrentActiveRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'viewer';

    final doc = await _users.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return 'viewer';

    final data = doc.data()!;
    final connectedCode = (data['connectedDeviceCode'] ?? '').toString();

    final activeRoleByCode =
    Map<String, dynamic>.from(data['activeRoleByCode'] ?? {});

    if (connectedCode.isNotEmpty && activeRoleByCode.containsKey(connectedCode)) {
      return (activeRoleByCode[connectedCode] ?? 'viewer').toString();
    }

    return (data['role'] ?? 'viewer').toString();
  }

  /// Optional: get connected device code
  static Future<String?> getConnectedDeviceCode() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    final code = data['connectedDeviceCode'];
    return code?.toString();
  }

  /// Update first name and last name
  static Future<({bool success, String message})> updateName({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return (success: false, message: 'No user is signed in.');
      }

      await _users.doc(user.uid).update({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      });

      await user.updateDisplayName('${firstName.trim()} ${lastName.trim()}');

      return (success: true, message: 'Name updated successfully.');
    } catch (e) {
      return (
      success: false,
      message: 'Failed to update name. Please try again.'
      );
    }
  }

  /// Change password
  static Future<({bool success, String message})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return (success: false, message: 'No user is signed in.');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return (success: true, message: 'Password changed successfully.');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return (success: false, message: 'Current password is incorrect.');
        case 'weak-password':
          return (success: false, message: 'New password is too weak.');
        case 'requires-recent-login':
          return (
          success: false,
          message: 'Please log out and log in again before changing your password.'
          );
        default:
          return (
          success: false,
          message: 'Failed to change password: ${e.message}'
          );
      }
    } catch (e) {
      return (
      success: false,
      message: 'Something went wrong. Please try again.'
      );
    }
  }

  static bool get canChangePassword {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  static String? get currentEmail => _auth.currentUser?.email;
  static String? get currentPhotoUrl => _auth.currentUser?.photoURL;
}