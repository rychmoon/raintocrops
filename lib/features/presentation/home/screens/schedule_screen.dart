import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/gestures.dart';

import 'appbar/schedule_appbar.dart';
import 'sub_screen/add_schedule.dart';
import '../widgets/add_schedule_icon.dart';
import '/core/widgets/global_snackbar.dart';

import '/features/auth/data/services/irrigation_schedule.dart';
import '/features/auth/data/models/irrigation_schedule.dart';
import '/features/irrigation/controller/irrigation_controller.dart';
import '/features/roles/controller/device_session_controller.dart';
import '../widgets/saved_schedule_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final IrrigationScheduleService _scheduleService =
  IrrigationScheduleService();

  bool _canManageSchedule(BuildContext context) {
    final session = context.read<DeviceSessionController>();
    return session.canControl;
  }

  String? _currentPairCode(BuildContext context) {
    return context.read<DeviceSessionController>().pairedCode;
  }

  void _showNoSchedulePermissionSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF374151),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only the owner or users with permission can manage schedules.',
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

  void _openEditSchedule(IrrigationScheduleModel schedule) {
    if (!_canManageSchedule(context)) {
      _showNoSchedulePermissionSnackbar(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddScheduleSubScreen(schedule: schedule),
      ),
    );
  }

  Future<void> _updateScheduleActiveState(
      IrrigationScheduleModel schedule,
      bool newValue,
      ) async {
    if (!_canManageSchedule(context)) {
      _showNoSchedulePermissionSnackbar(context);
      return;
    }

    final pairCode = _currentPairCode(context);
    if (pairCode == null || pairCode.isEmpty) {
      GlobalSnackbar.error(context, 'No connected device found');
      return;
    }

    try {
      final irrigation = context.read<IrrigationController>();

      await _scheduleService.updateScheduleStatus(
        pairCode: pairCode,
        scheduleId: schedule.id,
        isActive: newValue,
      );

      final espId = schedule.espScheduleId;
      if (espId != null) {
        irrigation.toggleSchedule(
          id: espId,
          active: newValue,
        );
      }

      if (!mounted) return;

      GlobalSnackbar.success(
        context,
        newValue ? 'Schedule activated' : 'Schedule deactivated',
      );
    } catch (e) {
      if (!mounted) return;

      GlobalSnackbar.error(
        context,
        'Failed to update schedule status',
      );
    }
  }

  void _showScheduleMenu(IrrigationScheduleModel schedule) {
    if (!_canManageSchedule(context)) {
      _showNoSchedulePermissionSnackbar(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _openEditSchedule(schedule);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showScheduleDetails(schedule);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(schedule);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showScheduleDetails(IrrigationScheduleModel schedule) {
    final title = schedule.note.isEmpty ? 'Untitled Schedule' : schedule.note;
    final days =
    schedule.isEveryday ? 'Everyday' : schedule.selectedDays.join(', ');
    final status = schedule.isActive ? 'Active' : 'Inactive';
    final createdBy =
    schedule.createdBy.isEmpty ? 'Unknown' : schedule.createdBy;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schedule Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: $title'),
              const SizedBox(height: 8),
              Text('Time: ${_formatTime(schedule.hour, schedule.minute)}'),
              const SizedBox(height: 8),
              Text('Days: $days'),
              const SizedBox(height: 8),
              Text('Status: $status'),
              const SizedBox(height: 8),
              Text('Created by: $createdBy'),
              if (schedule.espScheduleId != null) ...[
                const SizedBox(height: 8),
                Text('ESP ID: ${schedule.espScheduleId}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(IrrigationScheduleModel schedule) {
    if (!_canManageSchedule(context)) {
      _showNoSchedulePermissionSnackbar(context);
      return;
    }

    final title = schedule.note.isEmpty ? 'Untitled' : schedule.note;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Schedule'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final pairCode = _currentPairCode(context);
                if (pairCode == null || pairCode.isEmpty) {
                  if (!mounted) return;
                  GlobalSnackbar.error(context, 'No connected device found');
                  return;
                }

                try {
                  final irrigation = context.read<IrrigationController>();

                  if (schedule.espScheduleId != null) {
                    irrigation.deleteSchedule(id: schedule.espScheduleId!);
                  }

                  await _scheduleService.deleteSchedule(
                    pairCode: pairCode,
                    scheduleId: schedule.id,
                  );

                  if (!mounted) return;
                  GlobalSnackbar.error(context, 'Schedule deleted');
                } catch (e) {
                  if (!mounted) return;
                  GlobalSnackbar.error(context, 'Failed to delete schedule');
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int hour, int minute) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$mm $period';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DeviceSessionController>();
    final canManage = session.canControl;
    final pairCode = session.pairedCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScheduleAppBar(selectedMode: 'schedule'),
            const SizedBox(height: 20),
            Expanded(
              child: (pairCode == null || pairCode.isEmpty)
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Lottie.asset(
                          'assets/lottie/connect.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Connect a device first',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pair your device to start creating schedules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : StreamBuilder<List<IrrigationScheduleModel>>(
                stream: _scheduleService.getSchedules(
                  pairCode: pairCode,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final schedules = snapshot.data ?? [];

                  if (schedules.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 168,
                              height: 168,
                              child: ClipRect(
                                child: Lottie.asset(
                                  'assets/lottie/Clock.json',
                                  repeat: true,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No schedules yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.1,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.55,
                                  letterSpacing: 0.1,
                                  color: Color(0xFF6B7280),
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                    'Add one to keep your plants watered on time and make irrigation easier. ',
                                  ),
                                  TextSpan(
                                    text: 'Click here',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF38BDF8),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF38BDF8),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        if (!canManage) {
                                          _showNoSchedulePermissionSnackbar(context);
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const AddScheduleSubScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: schedules.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];

                      return SavedScheduleCard(
                        schedule: schedule,
                        canManage: canManage,
                        onTap: () {
                          if (!canManage) {
                            _showNoSchedulePermissionSnackbar(context);
                            return;
                          }
                          _openEditSchedule(schedule);
                        },
                        onLongPress: () {
                          if (!canManage) {
                            _showNoSchedulePermissionSnackbar(context);
                            return;
                          }
                          _showScheduleMenu(schedule);
                        },
                        onToggle: (value) async {
                          await _updateScheduleActiveState(schedule, value);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Opacity(
        opacity: canManage ? 1 : 0.55,
        child: AddScheduleIcon(
          onTap: () {
            if (!canManage) {
              _showNoSchedulePermissionSnackbar(context);
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddScheduleSubScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}