import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/roles/controller/device_session_controller.dart';
import '/features/presentation/home/widgets/owner_access_card.dart';
import '/features/presentation/home/widgets/owner_controller_list_card.dart';

class AccessRequestsScreen extends StatelessWidget {
  const AccessRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121220) : const Color(0xFFF4F6FA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final bool isOwnerMode =
        session.isPaired && session.isOwner && session.pairedCode != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          isOwnerMode ? 'Manage Requests' : 'Device Access',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!session.isPaired) ...[
                _ModeHeader(
                  title: 'No paired device',
                  subtitle:
                  'Connect your device first before managing or requesting access.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _EmptyStateCard(
                  icon: Icons.devices_other_rounded,
                  title: 'No paired device yet',
                  subtitle:
                  'You need to connect a device before this section becomes available.',
                  isDark: isDark,
                ),
              ] else if (session.isOwner) ...[
                _ModeHeader(
                  title: 'Owner mode',
                  subtitle:
                  'Review pending requests and manage approved controllers for your paired device.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                const OwnerAccessRequestsCard(),
                const OwnerControllerListCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(
                    'Approve, reject, or remove users who can control your device.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: textSecondary,
                    ),
                  ),
                ),
              ] else ...[
                _ModeHeader(
                  title: 'Viewer mode',
                  subtitle:
                  'Only the device owner can approve or reject access requests.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _EmptyStateCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Owner approval required',
                  subtitle:
                  'You can monitor readings, but only the owner can review access requests from this screen.',
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _ModeHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color:
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3D) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3D) : const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? const Color(0xFFB0B7C3)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color:
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}