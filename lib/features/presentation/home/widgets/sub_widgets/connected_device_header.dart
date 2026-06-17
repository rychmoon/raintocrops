import 'package:flutter/material.dart';

import 'device_role_badges.dart';

class ConnectedDeviceHeader extends StatelessWidget {
  final String? pairedCode;
  final String? role;
  final bool isConnected;
  final VoidCallback? onAddTap;

  const ConnectedDeviceHeader({
    super.key,
    required this.pairedCode,
    required this.role,
    required this.isConnected,
    this.onAddTap,
  });

  bool get hasPairedDevice =>
      pairedCode != null && pairedCode!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.memory_rounded,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected device',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasPairedDevice
                      ? 'Code: $pairedCode'
                      : 'Add your ESP32 device to start monitoring',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (hasPairedDevice)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (role != null && role!.trim().isNotEmpty)
                  DeviceRoleBadge(role: role!),
                const SizedBox(height: 8),
                DeviceLiveBadge(isConnected: isConnected),
              ],
            )
          else
            InkWell(
              onTap: onAddTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 21,
                  color: Color(0xFF68707D),
                ),
              ),
            ),
        ],
      ),
    );
  }
}