import 'package:flutter/material.dart';
import '/features/auth/data/models/irrigation_schedule.dart';

class SavedScheduleCard extends StatelessWidget {
  final IrrigationScheduleModel schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool canManage;

  const SavedScheduleCard({
    super.key,
    required this.schedule,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
    this.canManage = true,
  });

  static const List<String> _shortDays = [
    'S', 'M', 'T', 'W', 'T', 'F', 'S',
  ];

  static const List<String> _fullDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String _formatMainTime(int hour, int minute) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$hour12:$mm';
  }

  String _formatPeriod(int hour) {
    return hour >= 12 ? 'PM' : 'AM';
  }

  int _dayNameToDateTimeWeekday(String day) {
    switch (day) {
      case 'Monday':
        return DateTime.monday;
      case 'Tuesday':
        return DateTime.tuesday;
      case 'Wednesday':
        return DateTime.wednesday;
      case 'Thursday':
        return DateTime.thursday;
      case 'Friday':
        return DateTime.friday;
      case 'Saturday':
        return DateTime.saturday;
      case 'Sunday':
        return DateTime.sunday;
      default:
        return -1;
    }
  }

  DateTime? _getNextScheduledDateTime() {
    final now = DateTime.now();

    if (schedule.isEveryday) {
      DateTime next = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.hour,
        schedule.minute,
      );

      if (!next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      return next;
    }

    if (schedule.selectedDays.isEmpty) return null;

    DateTime? closest;

    for (final day in schedule.selectedDays) {
      final targetWeekday = _dayNameToDateTimeWeekday(day);
      if (targetWeekday == -1) continue;

      int daysAhead = (targetWeekday - now.weekday) % 7;

      DateTime candidate = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.hour,
        schedule.minute,
      ).add(Duration(days: daysAhead));

      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 7));
      }

      if (closest == null || candidate.isBefore(closest)) {
        closest = candidate;
      }
    }

    return closest;
  }

  String _getTimeLeftText() {
    final nextSchedule = _getNextScheduledDateTime();
    if (nextSchedule == null) return 'No day set';

    final diff = nextSchedule.difference(DateTime.now());
    final totalMinutes = diff.inMinutes;

    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final minutes = totalMinutes % 60;

    if (days > 0) {
      if (hours == 0) return '${days}d left';
      return '${days}d ${hours}h left';
    }

    if (hours > 0) return '${hours}h ${minutes}m left';
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = schedule.isActive;
    final bool isReadOnly = !canManage;

    const Color activeCardColor = Colors.white;
    const Color inactiveCardColor = Color(0xFFF2F3F8);

    const Color primaryText = Colors.black;
    const Color secondaryText = Color(0xFF6B7280);
    const Color accentBlue = Colors.lightBlue;
    const Color unselectedDay = Color(0xFF9CA3AF);

    final Color titleColor =
    isActive ? primaryText : primaryText.withValues(alpha: 0.45);

    final Color timeColor =
    isActive ? primaryText : primaryText.withValues(alpha: 0.40);

    final Color secondaryColor =
    isActive ? secondaryText : secondaryText.withValues(alpha: 0.50);

    final double cardOpacity = isReadOnly
        ? (isActive ? 0.88 : 0.64)
        : (isActive ? 1.0 : 0.75);

    final Color borderColor = isReadOnly
        ? const Color(0xFFE5E7EB)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: cardOpacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: canManage ? onLongPress : null,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: isActive ? activeCardColor : inactiveCardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isReadOnly ? 0.035 : 0.10,
                  ),
                  blurRadius: isReadOnly ? 10 : 20,
                  offset: Offset(0, isReadOnly ? 3 : 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.note.isEmpty ? 'Untitled' : schedule.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _formatMainTime(schedule.hour, schedule.minute),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: timeColor,
                          height: 0.95,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _formatPeriod(schedule.hour),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (schedule.isEveryday)
                  Text(
                    'Everyday',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isReadOnly
                          ? accentBlue.withValues(alpha: 0.55)
                          : accentBlue,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_shortDays.length, (index) {
                      final isSelected = schedule.selectedDays.contains(
                        _fullDays[index],
                      );

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (isReadOnly
                                  ? accentBlue.withValues(alpha: 0.55)
                                  : accentBlue)
                                  : Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _shortDays[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? (isReadOnly
                                  ? accentBlue.withValues(alpha: 0.55)
                                  : accentBlue)
                                  : unselectedDay.withValues(
                                alpha: isActive ? 1 : 0.45,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                const Spacer(),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _getTimeLeftText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IgnorePointer(
                      ignoring: isReadOnly,
                      child: Transform.scale(
                        scale: 0.84,
                        child: Opacity(
                          opacity: isReadOnly ? 0.38 : 1,
                          child: Switch(
                            value: schedule.isActive,
                            onChanged: canManage ? onToggle : null,
                            activeThumbColor: Colors.white,
                            activeTrackColor: accentBlue,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFE4E6EE),
                            trackOutlineColor:
                            WidgetStateProperty.all(Colors.transparent),
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
      ),
    );
  }
}