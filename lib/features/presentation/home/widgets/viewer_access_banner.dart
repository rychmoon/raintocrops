import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raintocrops/core/widgets/app_snackbar.dart';
import 'package:raintocrops/features/presentation/home/widgets/sub_widgets/device_role_badges.dart';
import 'package:raintocrops/features/roles/controller/device_session_controller.dart';
import 'package:raintocrops/features/roles/service/device_service.dart';

class ViewerAccessBanner extends StatefulWidget {
  final bool isInline;

  const ViewerAccessBanner({
    super.key,
    this.isInline = false,
  });

  @override
  State<ViewerAccessBanner> createState() => _ViewerAccessBannerState();
}

class _ViewerAccessBannerState extends State<ViewerAccessBanner> {
  bool _isSubmitting = false;
  bool _isSyncingApprovedRole = false;
  bool _hasShownApprovedDialog = false;

  Future<Map<String, String?>> _getOwnerProfile(String pairCode) async {
    final deviceDoc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(pairCode)
        .get();

    if (!deviceDoc.exists || deviceDoc.data() == null) {
      return {
        'firstName': null,
        'lastName': null,
        'email': null,
        'photoUrl': null,
      };
    }

    final ownerUid = (deviceDoc.data()!['ownerUid'] ?? '').toString().trim();
    if (ownerUid.isEmpty) {
      return {
        'firstName': null,
        'lastName': null,
        'email': null,
        'photoUrl': null,
      };
    }

    final ownerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .get();

    if (!ownerDoc.exists || ownerDoc.data() == null) {
      return {
        'firstName': null,
        'lastName': null,
        'email': null,
        'photoUrl': null,
      };
    }

    final data = ownerDoc.data()!;

    final firstName = (data['firstName'] ?? '').toString().trim();
    final lastName = (data['lastName'] ?? '').toString().trim();
    final username = (data['username'] ?? '').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final photoUrl = ((data['photoUrl'] ?? data['googlePhotoUrl']) ?? '')
        .toString()
        .trim();

    String resolvedFirstName = firstName;
    String resolvedLastName = lastName;

    if (resolvedFirstName.isEmpty &&
        resolvedLastName.isEmpty &&
        username.isNotEmpty) {
      final parts = username
          .split(' ')
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (parts.isNotEmpty) {
        resolvedFirstName = parts.first.trim();
        if (parts.length > 1) {
          resolvedLastName = parts.sublist(1).join(' ').trim();
        }
      }
    }

    if (resolvedFirstName.isEmpty &&
        resolvedLastName.isEmpty &&
        email.isNotEmpty) {
      resolvedFirstName = email.split('@').first.trim();
    }

    return {
      'firstName': resolvedFirstName.isEmpty ? 'Device' : resolvedFirstName,
      'lastName': resolvedLastName.isEmpty ? 'Owner' : resolvedLastName,
      'email': email.isEmpty ? null : email,
      'photoUrl': photoUrl.isEmpty ? null : photoUrl,
    };
  }

  String _buildInitials(String firstName, String lastName) {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final initials = '$first$last'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  Widget _buildOwnerAvatar({
    required String firstName,
    required String lastName,
    required String? photoUrl,
  }) {
    final initials = _buildInitials(firstName, lastName);

    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF42A5F5),
            Color(0xFF1E88E5),
          ],
        ),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          },
        )
            : Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPendingDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request pending',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your access request has already been sent. Please wait for the device owner to review and approve it.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showApprovedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Access approved',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You now have elevated access for this device. You can review and use the features allowed for your new role.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Nice',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRequestAccessDialog({
    required BuildContext context,
    required String pairCode,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ownerProfile = await _getOwnerProfile(pairCode);

    if (!mounted) return;

    final firstName = ownerProfile['firstName'] ?? 'Device';
    final lastName = ownerProfile['lastName'] ?? 'Owner';
    final email = ownerProfile['email'] ?? 'No email available';
    final photoUrl = ownerProfile['photoUrl'];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request access',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Send a request to the device owner to gain more control access.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This request will be sent to',
                        style: TextStyle(
                          fontSize: 13.3,
                          height: 1.45,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildOwnerAvatar(
                            firstName: firstName,
                            lastName: lastName,
                            photoUrl: photoUrl,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$firstName $lastName',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14.8,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF111827),
                                              letterSpacing: -0.1,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const DeviceRoleBadge(role: 'owner'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.6,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6B7280),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Send request',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await DeviceService().requestAccess(pairCode: pairCode);

      if (!mounted) return;

      if (messenger != null) {
        AppSnackbar.show(
          messenger.context,
          message: 'Access request sent to the owner.',
          type: AppSnackType.info,
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (messenger != null) {
        AppSnackbar.show(
          messenger.context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: AppSnackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();

    if (!session.isPaired || session.pairedCode == null || session.isOwner) {
      return const SizedBox.shrink();
    }

    final pairCode = session.pairedCode!;
    final sessionController = context.read<DeviceSessionController>();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: DeviceService().watchMyAccessRequest(pairCode: pairCode),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final status = (data?['status'] ?? '').toString();

        if (status == 'approved') {
          if (!_isSyncingApprovedRole) {
            _isSyncingApprovedRole = true;

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final updatedRole =
                await DeviceService().getMyRole(pairCode: pairCode);

                if (!mounted) return;
                await sessionController.updateRoleOnly(updatedRole);

                if (!_hasShownApprovedDialog && mounted) {
                  _hasShownApprovedDialog = true;
                  await _showApprovedDialog(context);
                }
              } finally {
                _isSyncingApprovedRole = false;
              }
            });
          }
        } else {
          _hasShownApprovedDialog = false;
        }

        late final String label;
        late final IconData icon;
        late final Color bgColor;
        late final Color borderColor;
        late final Color fgColor;

        if (_isSubmitting) {
          label = 'Sending...';
          icon = Icons.hourglass_top_rounded;
          bgColor = const Color(0xFFF8FAFC);
          borderColor = const Color(0xFFE5E7EB);
          fgColor = const Color(0xFF9CA3AF);
        } else if (status == 'pending') {
          label = 'Pending';
          icon = Icons.schedule_rounded;
          bgColor = const Color(0xFFF9FAFB);
          borderColor = const Color(0xFFE5E7EB);
          fgColor = const Color(0xFF6B7280);
        } else if (status == 'approved') {
          label = 'Approved';
          icon = Icons.check_circle_rounded;
          bgColor = const Color(0xFFF0FDF4);
          borderColor = const Color(0xFFBBF7D0);
          fgColor = const Color(0xFF15803D);
        } else if (session.role == 'controller') {
          label = 'Approved';
          icon = Icons.check_circle_rounded;
          bgColor = const Color(0xFFF0FDF4);
          borderColor = const Color(0xFFBBF7D0);
          fgColor = const Color(0xFF15803D);
        } else {
          label = 'Request access';
          icon = Icons.lock_open_rounded;
          bgColor = const Color(0xFFF0F9FF);
          borderColor = const Color(0xFFBAE6FD);
          fgColor = const Color(0xFF38BDF8);
        }

        return Padding(
          padding: widget.isInline
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _isSubmitting
                  ? null
                  : () {
                if (status == 'pending') {
                  _showPendingDialog(context);
                  return;
                }

                if (status == 'approved' || session.role == 'controller') {
                  _showApprovedDialog(context);
                  return;
                }

                _showRequestAccessDialog(
                  context: context,
                  pairCode: pairCode,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isInline ? 10 : 12,
                  vertical: widget.isInline ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSubmitting) ...[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                        ),
                      ),
                    ] else ...[
                      Icon(icon, size: 16, color: fgColor),
                    ],
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: fgColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}