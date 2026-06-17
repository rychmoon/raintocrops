import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raintocrops/core/widgets/app_snackbar.dart';
import 'package:raintocrops/core/notification/controller/notification_controller.dart';
import 'package:raintocrops/features/roles/controller/device_session_controller.dart';
import 'package:raintocrops/features/roles/service/device_service.dart';

class OwnerAccessRequestsCard extends StatelessWidget {
  const OwnerAccessRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();

    if (!session.isPaired || session.pairedCode == null) {
      return const _InfoCard(
        icon: Icons.devices_outlined,
        title: 'No paired device',
        subtitle: 'Connect your device first before reviewing access requests.',
      );
    }

    if (!session.isOwner) {
      return const _InfoCard(
        icon: Icons.lock_outline_rounded,
        title: 'Owner access only',
        subtitle: 'Only the device owner can review and approve access requests.',
      );
    }

    final pairCode = session.pairedCode!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DeviceService().watchPendingRequests(pairCode: pairCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InfoCard(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load requests',
            subtitle: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Loading access requests...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _InfoCard(
            icon: Icons.inbox_outlined,
            title: 'No pending requests',
            subtitle:
            'No one has requested access to your device yet.\n\nPair code: $pairCode',
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Access requests',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${docs.length} pending request${docs.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pair code: $pairCode',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 14),
              ...docs.map(
                    (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OwnerRequestTile(
                    pairCode: pairCode,
                    uid: doc.id,
                    data: doc.data(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OwnerRequestTile extends StatefulWidget {
  final String pairCode;
  final String uid;
  final Map<String, dynamic> data;

  const _OwnerRequestTile({
    required this.pairCode,
    required this.uid,
    required this.data,
  });

  @override
  State<_OwnerRequestTile> createState() => _OwnerRequestTileState();
}

class _OwnerRequestTileState extends State<_OwnerRequestTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final requestedRole =
    (widget.data['requestedRole'] ?? 'controller').toString();

    final requestedAt = widget.data['requestedAt'];
    String requestedAtText = 'Unknown time';

    if (requestedAt is Timestamp) {
      final dt = requestedAt.toDate();
      requestedAtText =
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get(),
      builder: (context, userSnapshot) {
        String displayName = 'Unknown user';
        String email = 'No email available';
        String photoUrl = '';

        if (userSnapshot.hasData && userSnapshot.data?.data() != null) {
          final userData = userSnapshot.data!.data()!;

          final firstName = (userData['firstName'] ?? '').toString().trim();
          final lastName = (userData['lastName'] ?? '').toString().trim();
          final fullName = '$firstName $lastName'.trim();

          displayName = fullName.isNotEmpty ? fullName : 'Unnamed user';
          email = (userData['email'] ?? 'No email available').toString().trim();

          photoUrl = (userData['photoUrl'] ?? userData['googlePhotoUrl'] ?? '')
              .toString()
              .trim();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Requested by',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF3F4F6),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: ClipOval(
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          );
                        },
                      )
                          : const Icon(
                        Icons.person_rounded,
                        size: 24,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Requested role: $requestedRole',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requested at: $requestedAtText',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                        setState(() => _busy = true);
                        try {
                          await DeviceService().rejectAccess(
                            pairCode: widget.pairCode,
                            targetUid: widget.uid,
                          );

                          if (!context.mounted) return;

                          context
                              .read<NotificationController>()
                              .addSystemNotification(
                            deviceId: widget.pairCode,
                            code: 'access_rejected',
                            title: 'Access rejected',
                            message:
                            '$displayName was rejected as controller.',
                            level: 'warning',
                            showLocalPush: true,
                          );

                          AppSnackbar.show(
                            context,
                            message: 'Request rejected.',
                            type: AppSnackType.info,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          AppSnackbar.show(
                            context,
                            message: e
                                .toString()
                                .replaceFirst('Exception: ', ''),
                            type: AppSnackType.error,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _busy = false);
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                        setState(() => _busy = true);
                        try {
                          await DeviceService().approveAccess(
                            pairCode: widget.pairCode,
                            targetUid: widget.uid,
                          );

                          if (!context.mounted) return;

                          context
                              .read<NotificationController>()
                              .addSystemNotification(
                            deviceId: widget.pairCode,
                            code: 'access_approved',
                            title: 'Access approved',
                            message:
                            '$displayName was approved as controller.',
                            level: 'info',
                            showLocalPush: true,
                          );

                          AppSnackbar.show(
                            context,
                            message: 'Request approved successfully.',
                            type: AppSnackType.success,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          AppSnackbar.show(
                            context,
                            message: e
                                .toString()
                                .replaceFirst('Exception: ', ''),
                            type: AppSnackType.error,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _busy = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}