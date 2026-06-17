import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/features/auth/data/models/irrigation_schedule.dart';
import '/features/auth/data/models/schedule_form_data.dart';
import '/features/auth/data/models/schedule_details_value.dart';
import '/features/auth/data/services/irrigation_schedule.dart';
import '/features/irrigation/controller/irrigation_controller.dart';
import '/features/presentation/home/screens/appbar/add_schedule_appbar.dart';
import '/features/presentation/home/widgets/time_picker.dart';
import '/features/presentation/home/widgets/schedule_details.dart';
import '/features/roles/controller/device_session_controller.dart';
import '/core/widgets/global_snackbar.dart';

class AddScheduleSubScreen extends StatefulWidget {
  final IrrigationScheduleModel? schedule;

  const AddScheduleSubScreen({
    super.key,
    this.schedule,
  });

  @override
  State<AddScheduleSubScreen> createState() => _AddScheduleSubScreenState();
}

class _AddScheduleSubScreenState extends State<AddScheduleSubScreen> {
  bool _isDraggingClock = false;
  bool _isButtonPressed = false;
  bool _isSaving = false;

  final IrrigationScheduleService _scheduleService = IrrigationScheduleService();
  ScheduleFormData _formData = ScheduleFormData.initial();

  bool get _isEditMode => widget.schedule != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final schedule = widget.schedule!;
      _formData = _formData.copyWith(
        selectedTime: TimeOfDay(hour: schedule.hour, minute: schedule.minute),
        selectedDays: List<String>.from(schedule.selectedDays),
        note: schedule.note,
        notificationsEnabled: schedule.notificationsEnabled,
        createdBy: schedule.createdBy,
      );
    }
  }

  void _setDragging(bool value) {
    if (_isDraggingClock == value) return;
    setState(() => _isDraggingClock = value);
  }

  String? _pairCode() {
    return context.read<DeviceSessionController>().pairedCode;
  }

  bool _hasScheduleConflict(
      List<IrrigationScheduleModel> schedules,
      List<String> newDays,
      TimeOfDay newTime,
      ) {
    final newMinutes = newTime.hour * 60 + newTime.minute;
    const minGapMinutes = 6 * 60;

    for (final schedule in schedules) {
      if (_isEditMode && schedule.id == widget.schedule!.id) continue;

      final existingMinutes = schedule.hour * 60 + schedule.minute;
      final hasSameDay = schedule.selectedDays.any(newDays.contains);

      if (!hasSameDay) continue;

      final difference = (existingMinutes - newMinutes).abs();
      if (difference < minGapMinutes) return true;
    }

    return false;
  }

  List<int> _mapDaysToEsp32(List<String> selectedDays) {
    return selectedDays
        .map((day) {
      switch (day) {
        case 'Sunday':
          return 0;
        case 'Monday':
          return 1;
        case 'Tuesday':
          return 2;
        case 'Wednesday':
          return 3;
        case 'Thursday':
          return 4;
        case 'Friday':
          return 5;
        case 'Saturday':
          return 6;
        default:
          return -1;
      }
    })
        .where((value) => value >= 0 && value <= 6)
        .toList();
  }

  String _formatTimeForEsp32(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<int?> _findCreatedEspScheduleId({
    required IrrigationController irrigation,
    required String time,
    required List<int> days,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    irrigation.requestState();
    await Future.delayed(const Duration(milliseconds: 900));

    final items = irrigation.schedules;

    for (final item in items) {
      final sameTime = item.time == time;
      final sameDays =
          item.days.length == days.length &&
              item.days.toSet().containsAll(days) &&
              days.toSet().containsAll(item.days);

      if (sameTime && sameDays) {
        return item.id;
      }
    }

    return null;
  }

  Future<void> _saveSchedule() async {
    if (_isSaving) return;

    HapticFeedback.lightImpact();

    final pairCode = _pairCode();
    if (pairCode == null || pairCode.isEmpty) {
      GlobalSnackbar.error(context, 'No connected device found');
      return;
    }

    if (_formData.selectedDays.isEmpty) {
      GlobalSnackbar.warning(context, 'Please select at least one day.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final schedules = await _scheduleService
          .getSchedules(pairCode: pairCode)
          .first;

      final hasConflict = _hasScheduleConflict(
        schedules,
        _formData.selectedDays,
        _formData.selectedTime,
      );

      if (hasConflict) {
        if (!mounted) return;
        GlobalSnackbar.warning(
          context,
          'Please keep irrigation schedules at least 6 hours apart.',
        );
        return;
      }

      final irrigation = context.read<IrrigationController>();

      final note = _formData.note.trim().isEmpty
          ? 'Untitled Schedule'
          : _formData.note.trim();

      final createdBy = _formData.createdBy.trim().isEmpty
          ? 'Unknown user'
          : _formData.createdBy.trim();

      final hour = _formData.selectedTime.hour;
      final minute = _formData.selectedTime.minute;
      final selectedDays = List<String>.from(_formData.selectedDays);
      final mqttDays = _mapDaysToEsp32(selectedDays);
      final mqttTime = _formatTimeForEsp32(hour, minute);

      if (_isEditMode) {
        final oldSchedule = widget.schedule!;
        final espId = oldSchedule.espScheduleId;

        await _scheduleService.updateSchedule(
          pairCode: pairCode,
          scheduleId: oldSchedule.id,
          note: note,
          hour: hour,
          minute: minute,
          duration: oldSchedule.duration,
          selectedDays: selectedDays,
          notificationsEnabled: _formData.notificationsEnabled,
          isActive: oldSchedule.isActive,
          createdBy: createdBy,
        );

        if (espId != null) {
          irrigation.editSchedule(
            id: espId,
            time: mqttTime,
            duration: oldSchedule.duration,
            days: mqttDays,
            active: oldSchedule.isActive,
          );
        } else {
          irrigation.addSchedule(
            time: mqttTime,
            duration: oldSchedule.duration,
            days: mqttDays,
            active: oldSchedule.isActive,
          );

          final newEspId = await _findCreatedEspScheduleId(
            irrigation: irrigation,
            time: mqttTime,
            days: mqttDays,
          );

          if (newEspId != null) {
            await _scheduleService.updateEspScheduleId(
              pairCode: pairCode,
              scheduleId: oldSchedule.id,
              espScheduleId: newEspId,
            );
          }
        }
      } else {
        final docId = await _scheduleService.addSchedule(
          pairCode: pairCode,
          note: note,
          hour: hour,
          minute: minute,
          duration: 60,
          selectedDays: selectedDays,
          notificationsEnabled: _formData.notificationsEnabled,
          isActive: true,
          createdBy: createdBy,
        );

        irrigation.addSchedule(
          time: mqttTime,
          duration: 60,
          days: mqttDays,
          active: true,
        );

        final newEspId = await _findCreatedEspScheduleId(
          irrigation: irrigation,
          time: mqttTime,
          days: mqttDays,
        );

        if (newEspId != null) {
          await _scheduleService.updateEspScheduleId(
            pairCode: pairCode,
            scheduleId: docId,
            espScheduleId: newEspId,
          );
        }
      }

      if (!mounted) return;

      GlobalSnackbar.success(
        context,
        _isEditMode
            ? 'Schedule updated successfully'
            : 'Schedule saved successfully',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      GlobalSnackbar.error(context, 'Failed to save schedule');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_isSaving) return;
    setState(() => _isButtonPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isButtonPressed = false);
    _saveSchedule();
  }

  void _onTapCancel() {
    setState(() => _isButtonPressed = false);
  }

  void _handleTimeChanged(TimeOfDay time) {
    setState(() {
      _formData = _formData.copyWith(selectedTime: time);
    });
  }

  void _handleDetailsChanged(ScheduleDetailsValue value) {
    setState(() {
      _formData = _formData.copyWith(
        selectedDays: value.selectedDays,
        note: value.note,
        notificationsEnabled: value.notificationsEnabled,
        createdBy: value.createdBy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottomInset > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AddScheduleAppbar(
          title: _isEditMode ? 'Edit Schedule' : 'Add Schedule',
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: _isDraggingClock
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    keyboardOpen ? bottomInset + 120 : 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Center(
                        child: TimePicker(
                          initialHour: _formData.selectedTime.hour,
                          initialMinute: _formData.selectedTime.minute,
                          onDragStart: () => _setDragging(true),
                          onDragEnd: () => _setDragging(false),
                          onTimeChanged: _handleTimeChanged,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ScheduleDetails(
                        onChanged: _handleDetailsChanged,
                        initialSelectedDays: _formData.selectedDays,
                        initialNote: _formData.note,
                        initialNotificationsEnabled:
                        _formData.notificationsEnabled,
                        initialCreatedBy: _formData.createdBy,
                      ),
                    ],
                  ),
                ),
              ),
              if (!keyboardOpen)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: GestureDetector(
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      child: AnimatedScale(
                        scale: _isButtonPressed ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isSaving
                                ? Colors.lightBlue.shade200
                                : _isButtonPressed
                                ? const Color(0xFF42A5F5)
                                : Colors.lightBlue,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: _isButtonPressed ? 0.14 : 0.26,
                                ),
                                blurRadius: _isButtonPressed ? 6 : 12,
                                offset: Offset(0, _isButtonPressed ? 2 : 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isSaving
                                ? (_isEditMode ? 'Updating...' : 'Saving...')
                                : (_isEditMode
                                ? 'Update Schedule'
                                : 'Save Schedule'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}