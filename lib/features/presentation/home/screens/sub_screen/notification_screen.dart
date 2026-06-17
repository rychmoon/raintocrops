import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';


import '/core/notification/controller/notification_controller.dart';
import '/features/irrigation/controller/irrigation_controller.dart';
import '/features/irrigation/models/notify_model.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<({String label, List<NotifyModel> items})> _groupByDate(
    List<NotifyModel> all,
    ) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));

  final today = <NotifyModel>[];
  final yesterday = <NotifyModel>[];
  final older = <NotifyModel>[];

  for (final n in all) {
    final d = DateTime.fromMillisecondsSinceEpoch(n.ts);
    if (!d.isBefore(todayStart)) {
      today.add(n);
    } else if (!d.isBefore(yesterdayStart)) {
      yesterday.add(n);
    } else {
      older.add(n);
    }
  }

  return [
    if (today.isNotEmpty) (label: 'Today', items: today),
    if (yesterday.isNotEmpty) (label: 'Yesterday', items: yesterday),
    if (older.isNotEmpty) (label: 'Earlier', items: older),
  ];
}

// ---------------------------------------------------------------------------
// Filter enum
// ---------------------------------------------------------------------------

enum _Filter { all, unread, alerts }

// ---------------------------------------------------------------------------
// NotificationScreen
// ---------------------------------------------------------------------------

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  _Filter _filter = _Filter.all;

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  bool _isAlertNotification(NotifyModel n) {
    final category = n.category.toLowerCase().trim();
    final title = n.title.toLowerCase().trim();
    final message = n.displayMessage.toLowerCase().trim();

    // If your model has level/code fields, you can safely uncomment these
    // if those fields exist in NotifyModel:
    //
    // final level = n.level.toLowerCase().trim();
    // final code = n.code.toLowerCase().trim();

    const alertCategories = [
      'alert',
      'warning',
      'warn',
      'error',
      'critical',
      'danger',
      'system alert',
    ];

    const alertKeywords = [
      'low tank',
      'tank low',
      'tank empty',
      'overflow',
      'too low',
      'too high',
      'ph low',
      'ph high',
      'unsafe ph',
      'blocked',
      'failed',
      'failure',
      'error',
      'offline',
      'disconnected',
      'no flow',
      'timeout',
      'empty bottle',
      'no liquid',
      'sensor error',
      'not responding',
      'pump failed',
      'valve failed',
      'critical',
      'warning',
      'alert',
    ];

    if (alertCategories.contains(category)) return true;

    if (_containsAny(category, alertKeywords)) return true;
    if (_containsAny(title, alertKeywords)) return true;
    if (_containsAny(message, alertKeywords)) return true;

    return false;
  }

  List<NotifyModel> _applyFilter(List<NotifyModel> items, _Filter filter) {
    return switch (filter) {
      _Filter.all => items,
      _Filter.unread => items.where((n) => !n.isRead).toList(),
      _Filter.alerts => items.where(_isAlertNotification).toList(),
    };
  }

  Future<bool?> _showClearAllDialog(
      BuildContext context, {
        required int count,
      }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
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
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Clear all notifications?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  count == 1
                      ? 'This will remove your only notification from this device.'
                      : 'This will permanently remove all $count notifications from this device.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Delete all',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = context.watch<NotificationController>();
    final irrigationController = context.watch<IrrigationController>();

    final deviceId = irrigationController.deviceId;
    final allItems = notificationController.itemsForDevice(deviceId);
    final unreadCount = notificationController.unreadCountForDevice(deviceId);
    final alertCount = allItems.where(_isAlertNotification).length;
    final filtered = _applyFilter(allItems, _filter);
    final grouped = _groupByDate(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF6F6F6),
        surfaceTintColor: const Color(0xFFF6F6F6),
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF6F6F6),
                  foregroundColor: Colors.lightBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    notificationController.markAllAsReadForDevice(deviceId),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (allItems.isNotEmpty && deviceId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Clear all',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () async {
                  final shouldDelete = await _showClearAllDialog(
                    context,
                    count: allItems.length,
                  );

                  if (shouldDelete == true && context.mounted) {
                    final deletedCount = allItems.length;
                    notificationController.clearForDevice(deviceId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          deletedCount == 1
                              ? 'Notification cleared'
                              : '$deletedCount notifications cleared',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF111827),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ),
        ],
      ),
      body: deviceId == null
          ? const _NoDeviceState()
          : allItems.isEmpty
          ? const _EmptyState()
          : Column(
        children: [
          _PillTabBar(
            selected: _filter,
            allCount: allItems.length,
            unreadCount: unreadCount,
            alertCount: alertCount,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyFilterState(
              isAlerts: _filter == _Filter.alerts,
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: grouped.fold<int>(
                0,
                    (sum, g) => sum + 1 + g.items.length,
              ),
              itemBuilder: (context, index) {
                int cursor = 0;
                for (final group in grouped) {
                  if (index == cursor) {
                    return _SectionLabel(label: group.label);
                  }
                  cursor++;
                  final localIndex = index - cursor;
                  if (localIndex < group.items.length) {
                    final item = group.items[localIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: ValueKey(
                          '${item.id}_${item.code}_${item.ts}',
                        ),
                        direction:
                        DismissDirection.endToStart,
                        background: _DismissBackground(),
                        onDismissed: (_) =>
                            notificationController
                                .removeNotification(item),
                        child: _NotificationCard(
                          item: item,
                          onTap: () => notificationController
                              .markAsRead(item),
                        ),
                      ),
                    );
                  }
                  cursor += group.items.length;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Swipe left to dismiss',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pill tab bar
// ---------------------------------------------------------------------------

class _PillTabBar extends StatelessWidget {
  final _Filter selected;
  final int allCount;
  final int unreadCount;
  final int alertCount;
  final ValueChanged<_Filter> onChanged;

  const _PillTabBar({
    required this.selected,
    required this.allCount,
    required this.unreadCount,
    required this.alertCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          _PillTab(
            label: 'All ($allCount)',
            active: selected == _Filter.all,
            onTap: () => onChanged(_Filter.all),
          ),
          const SizedBox(width: 8),
          _PillTab(
            label: unreadCount > 0 ? 'Unread ($unreadCount)' : 'Unread',
            active: selected == _Filter.unread,
            onTap: () => onChanged(_Filter.unread),
          ),
          const SizedBox(width: 8),
          _PillTab(
            label: alertCount > 0 ? 'Alerts ($alertCount)' : 'Alerts',
            active: selected == _Filter.alerts,
            onTap: () => onChanged(_Filter.alerts),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  static const _activeBg = Colors.lightBlue;
  static const _inactiveBg = Color(0xFFF3F4F6);
  static const _inactiveColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _activeBg : _inactiveBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _inactiveColor,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification card
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  final NotifyModel item;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.accentColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFEAF4FF),
              width: 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 3,
                    color: item.isRead
                        ? Colors.transparent
                        : accent.withValues(alpha: 0.65),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: item.isRead
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                          color: const Color(0xFF111827),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.relativeTime,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.displayMessage,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.08),
                                        borderRadius:
                                        BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!item.isRead)
                                      AnimatedContainer(
                                        duration:
                                        const Duration(milliseconds: 300),
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.75),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dismiss background
// ---------------------------------------------------------------------------

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

class _NoDeviceState extends StatelessWidget {
  const _NoDeviceState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/lottie/notification.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No device connected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pair your device to see notifications and alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_notification.webp',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Updates about watering, tank level, schedules, and alerts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final bool isAlerts;

  const _EmptyFilterState({
    this.isAlerts = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAlerts ? Icons.inbox_outlined : Icons.inbox_outlined,
              size: 48,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 14),
            Text(
              isAlerts ? 'No alerts right now' : 'No alerts right now',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAlerts
                  ? 'Critical warnings and important issues will appear here.'
                  : 'Critical warnings and important issues will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}