import 'package:flutter/material.dart';
import '/features/auth/data/models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double size;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      imageUrl = user.photoUrl;
    }

    else if (!user.hideGooglePhoto &&
        user.googlePhotoUrl != null &&
        user.googlePhotoUrl!.isNotEmpty) {
      imageUrl = user.googlePhotoUrl;
    }

    if (imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF42A5F5), // lightBlue.shade400
            Color(0xFF1E88E5), // blue.shade600
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}