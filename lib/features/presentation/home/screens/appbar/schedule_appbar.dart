import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/presentation/home/screens/sub_screen/manual_mode.dart';
import '/features/presentation/home/widgets/viewer_access_banner.dart';
import '/features/roles/controller/device_session_controller.dart';

class ScheduleAppBar extends StatelessWidget {
  final String selectedMode;

  const ScheduleAppBar({
    super.key,
    this.selectedMode = 'schedule',
  });

  void _showNoManualAccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF374151),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: const [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only the owner or users with permission can use manual mode.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<DeviceSessionController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text(
            selectedMode == 'manual' ? 'Manual Mode' : 'Schedule',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          const ViewerAccessBanner(isInline: true),
          const SizedBox(width: 2),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 22,
              color: Colors.black87,
            ),
            position: PopupMenuPosition.under,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == selectedMode) return;

              if (value == 'manual') {
                if (!session.canControl) {
                  _showNoManualAccessSnackbar(context);
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManualModeScreen(),
                  ),
                );
              } else if (value == 'schedule') {
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'schedule',
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: _ModeMenuTile(
                  label: 'Schedule',
                  icon: Icons.schedule_rounded,
                  isActive: selectedMode == 'schedule',
                ),
              ),
              PopupMenuItem<String>(
                value: 'manual',
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: _ModeMenuTile(
                  label: 'Manual',
                  icon: Icons.pan_tool_alt_outlined,
                  isActive: selectedMode == 'manual',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeMenuTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const _ModeMenuTile({
    required this.label,
    required this.icon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Colors.lightBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (isActive)
            const Icon(
              Icons.check_rounded,
              size: 18,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}