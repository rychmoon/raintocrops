import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '/features/auth/data/models/user_model.dart';
import '/core/notification/controller/notification_controller.dart';
import '/features/irrigation/controller/irrigation_controller.dart';
import '/features/presentation/home/screens/sub_screen/notification_screen.dart';
import '../../widgets/user_avatar.dart';

class WelcomeAppBar extends StatelessWidget {
  final UserModel user;

  const WelcomeAppBar({
    super.key,
    required this.user,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning,';
    } else if (hour >= 12 && hour < 18) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  String _getDisplayName() {
    if (user.firstName.trim().isNotEmpty) {
      return user.firstName.trim();
    }

    if (user.email.trim().isNotEmpty) {
      return user.email.split('@').first;
    }

    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = context.watch<NotificationController>();
    final irrigationController = context.watch<IrrigationController>();

    final deviceId = irrigationController.deviceId;
    final notifCount = notificationController.unreadCountForDevice(deviceId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            UserAvatar(
              user: user,
              size: 40,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _getDisplayName(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),

        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                FontAwesome.bell,
                size: 19,
                color: Colors.black87,
              ),

              if (notifCount > 0)
                Positioned(
                  top: -9.8,
                  right: -6.5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF6F6F6),
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        notifCount > 9 ? '9+' : notifCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}