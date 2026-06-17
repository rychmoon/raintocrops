import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/services/profile_service.dart';
import '../../../auth/data/services/google_auth.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/login.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raintocrops/features/roles/service/device_service.dart';

import '/core/notification/controller/notification_controller.dart';
import '/features/presentation/home/screens/sub_screen/about_app_screen.dart';
import '/features/presentation/home/screens/sub_screen/notification_screen.dart';
import '/features/presentation/home/screens/sub_screen/change_password_screen.dart';
import '/features/presentation/home/screens/sub_screen/terms_conditions_screen.dart';
import '/features/presentation/home/screens/sub_screen/access_request_screen.dart';
import '/features/presentation/home/screens/sub_screen/search_wifi_connection.dart';
import '/features/presentation/home/widgets/cloud_indicator.dart';

import '/features/irrigation/controller/irrigation_controller.dart';
import '/features/roles/controller/device_session_controller.dart';
import '/features/presentation/home/widgets/sub_widgets/device_role_badges.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color _primaryBlue = Color(0xFF42A5F5);
  static const Color _primaryBlueDark = Color(0xFF1E88E5);

  static const Color _lightBg = Color(0xFFF4F6FA);
  static const Color _lightCard = Colors.white;

  static const Color _iconBgLight = Color(0xFFECEFF3);
  static const Color _iconColorLight = Color(0xFF6B7280);
  static const Color _textPrimaryLight = Color(0xFF111827);
  static const Color _textSecondaryLight = Color(0xFF6B7280);
  static const Color _textMutedLight = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await ProfileService.getCurrentUserData();
    if (!mounted) return;

    setState(() {
      _user = userData;
      _isLoading = false;
    });
  }

  String _getInitials() {
    if (_user == null) return '?';
    final first = _user!.firstName.isNotEmpty ? _user!.firstName[0] : '';
    final last = _user!.lastName.isNotEmpty ? _user!.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  String _resolvedRole(DeviceSessionController session) {
    final sessionRole = session.role?.trim();
    if (sessionRole != null && sessionRole.isNotEmpty) {
      return sessionRole.toLowerCase();
    }

    final userRole = _user?.role.trim();
    if (userRole != null && userRole.isNotEmpty) {
      return userRole.toLowerCase();
    }

    return 'viewer';
  }

  String? _resolvedCode(DeviceSessionController session) {
    final code = session.pairedCode?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }
    return null;
  }

  void _showEditNameDialog() {
    final firstNameController =
    TextEditingController(text: _user?.firstName ?? '');
    final lastNameController =
    TextEditingController(text: _user?.lastName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => _EditNameDialog(
        firstNameController: firstNameController,
        lastNameController: lastNameController,
        onSave: () async {
          Navigator.of(ctx).pop();

          if (mounted) {
            setState(() => _isSaving = true);
          }

          final result = await ProfileService.updateName(
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
          );

          await _loadUserData();

          if (!mounted) return;
          setState(() => _isSaving = false);
          _showSnackBar(result.message, result.success);
        },
      ),
    );
  }

  Future<void> _openChangePasswordScreen() async {
    if (!ProfileService.canChangePassword) {
      _showSnackBar(
        'Password change is not available for Google-only accounts.',
        false,
      );
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ),
    );

    if (changed == true && mounted) {
      _showSnackBar('Password updated successfully.', true);
    }
  }

  void _openAddConnectionsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchWiFiConnection(),
      ),
    );
  }

  void _showSnackBar(String message, bool success) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A3D)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A3D)
                      : const Color(0xFFECEFF3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 24,
                  color: isDark
                      ? const Color(0xFFB0B7C3)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to logout from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252536)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF323248)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final irrigationController = context.read<IrrigationController>();

      await irrigationController.disconnect();

      await GoogleAuthService.signOut();
      await AuthService().signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Logout failed: $e', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = context.watch<DeviceSessionController>();
    final notificationController = context.watch<NotificationController>();
    final irrigationController = context.watch<IrrigationController>();

    final deviceId = irrigationController.deviceId;
    final notifCount = notificationController.unreadCountForDevice(deviceId);

    final resolvedRole = _resolvedRole(session);
    final resolvedCode = _resolvedCode(session);

    final cardColor = isDark ? const Color(0xFF1E1E2E) : _lightCard;
    final subtitleColor = isDark ? Colors.grey.shade400 : _textSecondaryLight;
    final dividerColor = isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade200;
    final bgColor = isDark ? const Color(0xFF121220) : _lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: IgnorePointer(
              ignoring: _isSaving,
              child: _isLoading
                  ? const Center(
                child: CustomLoadingAnimation(),
              )
                  : RefreshIndicator(
                onRefresh: _loadUserData,
                color: _primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildProfileCard(
                        theme,
                        isDark,
                        cardColor,
                        subtitleColor,
                        resolvedRole,
                        resolvedCode,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionLabel('Account', theme),
                      const SizedBox(height: 8),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        dividerColor: dividerColor,
                        isDark: isDark,
                        children: [
                          _buildSettingsTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Name',
                            subtitle:
                            '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}',
                            onTap: _showEditNameDialog,
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildSettingsTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Change Password',
                            subtitle: ProfileService.canChangePassword
                                ? 'Open password settings'
                                : 'Not available for Google accounts',
                            onTap: _openChangePasswordScreen,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildSectionLabel('Preferences', theme),
                      const SizedBox(height: 8),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        dividerColor: dividerColor,
                        isDark: isDark,
                        children: [
                          _buildSettingsTile(
                            icon: Icons.wifi_rounded,
                            title: 'Add Connections',
                            subtitle:
                            'Scan nearby WiFi, choose a network and send it to your device.',
                            onTap: _openAddConnectionsScreen,
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: dividerColor),

                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildSettingsTile(
                                icon: Icons.notifications_none_rounded,
                                title: 'Notifications',
                                subtitle: 'Check latest updates',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const NotificationScreen(),
                                    ),
                                  );
                                },
                                isDark: isDark,
                              ),
                              if (notifCount > 0)
                                Positioned(
                                  top: 10,
                                  right: 14,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 22,
                                      minHeight: 22,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius:
                                      BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF111827)
                                            : Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.10,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      notifCount > 99
                                          ? '99+'
                                          : notifCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          if (session.isOwner) ...[
                            Divider(height: 1, color: dividerColor),
                            StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>>(
                              stream: session.pairedCode != null
                                  ? DeviceService().watchPendingRequests(
                                pairCode: session.pairedCode!,
                              )
                                  : null,
                              builder: (context, snapshot) {
                                final pendingCount =
                                    snapshot.data?.docs.length ?? 0;

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildSettingsTile(
                                      icon: Icons
                                          .admin_panel_settings_outlined,
                                      title: 'Manage Requests',
                                      subtitle:
                                      'Review pending device access requests',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                            const AccessRequestsScreen(),
                                          ),
                                        );
                                      },
                                      isDark: isDark,
                                    ),
                                    if (pendingCount > 0)
                                      Positioned(
                                        top: 10,
                                        right: 14,
                                        child: Container(
                                          constraints:
                                          const BoxConstraints(
                                            minWidth: 22,
                                            minHeight: 22,
                                          ),
                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                            const Color(0xFFEF4444),
                                            borderRadius:
                                            BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(
                                                  0xFF111827)
                                                  : Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(
                                                  alpha: 0.10,
                                                ),
                                                blurRadius: 10,
                                                offset:
                                                const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            pendingCount > 99
                                                ? '99+'
                                                : pendingCount
                                                .toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSectionLabel('Information', theme),
                      const SizedBox(height: 8),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        dividerColor: dividerColor,
                        isDark: isDark,
                        children: [
                          _buildSettingsTile(
                            icon: Icons.description_outlined,
                            title: 'Terms & Conditions',
                            subtitle: 'Read our terms',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const TermsConditionsScreen(),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildSettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About',
                            subtitle: 'Version 1.0.0',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AboutScreen(),
                                ),
                              );
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: InkWell(
                          onTap: _handleLogout,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E2E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2A2A3D)
                                    : const Color(0xFFE5E7EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.4 : 0.03,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A2A3D)
                                        : const Color(0xFFECEFF3),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFFB0B7C3)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: isDark
                                      ? const Color(0xFF8E97A8)
                                      : const Color(0xFF6B7280),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CustomLoadingAnimation(),
                      const SizedBox(height: 14),
                      Text(
                        'Please wait...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.96),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      ThemeData theme,
      bool isDark,
      Color cardColor,
      Color subtitleColor,
      String resolvedRole,
      String? resolvedCode,
      ) {
    final photoUrl = ProfileService.currentPhotoUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _primaryBlue,
                  _primaryBlueDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: photoUrl != null
                ? ClipOval(
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildInitialsAvatar(),
              ),
            )
                : _buildInitialsAvatar(),
          ),
          const SizedBox(height: 16),
          Text(
            '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ProfileService.currentEmail ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 12),
          DeviceRoleBadge(role: resolvedRole),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _getInitials(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required Color cardColor,
    required Color dividerColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final iconBg = isDark ? const Color(0xFF2A2A3D) : _iconBgLight;
    final iconColor = isDark ? const Color(0xFFB0B7C3) : _iconColorLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : _textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade500
                            : _textSecondaryLight,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF8E97A8) : _textMutedLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onSave;

  const _EditNameDialog({
    required this.firstNameController,
    required this.lastNameController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Edit Name',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF6B7280),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              prefixIcon: const Icon(
                Icons.person_outline,
                color: Color(0xFF6B7280),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}