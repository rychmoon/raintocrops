import 'package:flutter/material.dart';

class DeviceRoleBadge extends StatelessWidget {
  final String role;

  const DeviceRoleBadge({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedRole = role.toLowerCase();

    final Color badgeBg = switch (normalizedRole) {
      'owner' => const Color(0xFFE0F2FE),
      'controller' => const Color(0xFFDCFCE7),
      _ => const Color(0xFFF3F4F6),
    };

    final Color badgeFg = switch (normalizedRole) {
      'owner' => const Color(0xFF0369A1),
      'controller' => const Color(0xFF15803D),
      _ => const Color(0xFF4B5563),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalizedRole.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: badgeFg,
        ),
      ),
    );
  }
}

class DeviceLiveBadge extends StatelessWidget {
  final bool isConnected;

  const DeviceLiveBadge({
    super.key,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isConnected
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    final String stateText = isConnected ? 'Live' : 'Connecting';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          stateText,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: dotColor,
          ),
        ),
      ],
    );
  }
}