import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/data/services/irrigation_schedule.dart';
import '/features/auth/data/models/irrigation_schedule.dart';
import '/features/irrigation/controller/irrigation_controller.dart';
import '/features/roles/controller/device_session_controller.dart';

import 'conn_dev_item_card.dart';
import '/features/presentation/home/widgets/sub_widgets/connected_device_state.dart';

enum CardFilter { all, soil, tank, pond, ph, rain, schedule }

class ConnectedDevicesCard extends StatefulWidget {
  const ConnectedDevicesCard({super.key});

  @override
  State<ConnectedDevicesCard> createState() => _ConnectedDevicesCardState();
}

class _ConnectedDevicesCardState extends State<ConnectedDevicesCard> {
  Timer? _timer;
  CardFilter _selectedFilter = CardFilter.all;

  final GlobalKey _cardsGridKey = GlobalKey();

  static const int _soilDryRaw = 3200;
  static const int _soilWetRaw = 1400;

  static const Color _neutralColor = Color(0xFF94A3B8);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _criticalColor = Color(0xFFEF4444);

  static const Color _accentBlue = Color(0xFF60A5FA);
  static const Color _accentBlueStrong = Color(0xFF3B82F6);
  static const Color _inactiveChipText = Color(0xFF475569);

  Color get _primaryColor => _accentBlue;
  Color get _primaryStrongColor => _accentBlueStrong;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scrollToCards() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cardsGridKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  Widget _buildFilterBar() {
    Widget chip(String label, CardFilter value) {
      final selected = _selectedFilter == value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _inactiveChipText,
            ),
          ),
          selected: selected,
          onSelected: (_) {
            if (_selectedFilter == value) return;
            setState(() => _selectedFilter = value);
            if (value == CardFilter.all) _scrollToCards();
          },
          selectedColor: _accentBlue,
          side: BorderSide(
            color: selected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          showCheckmark: false,
          elevation: selected ? 1.5 : 0,
          pressElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', CardFilter.all),
          const SizedBox(width: 8),
          chip('Soil', CardFilter.soil),
          const SizedBox(width: 8),
          chip('Tank', CardFilter.tank),
          const SizedBox(width: 8),
          chip('Pond', CardFilter.pond),
          const SizedBox(width: 8),
          chip('pH', CardFilter.ph),
          const SizedBox(width: 8),
          chip('Rain', CardFilter.rain),
          const SizedBox(width: 8),
          chip('Schedule', CardFilter.schedule),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$mm $period';
  }

  String _formatCountdown(Duration diff) {
    if (diff.inSeconds <= 0) return "Now";
    if (diff.inMinutes <= 5) return "Soon";

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days > 0) return "${days}d ${hours}h left";

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')} left";
  }

  int? _weekdayFromString(String day) {
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
        return null;
    }
  }

  DateTime _nextOccurrence(IrrigationScheduleModel schedule) {
    final now = DateTime.now();
    DateTime? nearest;

    for (final day in schedule.selectedDays) {
      final targetWeekday = _weekdayFromString(day);
      if (targetWeekday == null) continue;

      int daysAhead = targetWeekday - now.weekday;
      if (daysAhead < 0) daysAhead += 7;

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

      if (nearest == null || candidate.isBefore(nearest)) {
        nearest = candidate;
      }
    }

    return nearest ?? now;
  }

  DateTime _previousOccurrence(IrrigationScheduleModel schedule) {
    final now = DateTime.now();
    DateTime? latest;

    for (final day in schedule.selectedDays) {
      final targetWeekday = _weekdayFromString(day);
      if (targetWeekday == null) continue;

      int daysBehind = now.weekday - targetWeekday;
      if (daysBehind < 0) daysBehind += 7;

      DateTime candidate = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.hour,
        schedule.minute,
      ).subtract(Duration(days: daysBehind));

      if (!candidate.isBefore(now)) {
        candidate = candidate.subtract(const Duration(days: 7));
      }

      if (latest == null || candidate.isAfter(latest)) {
        latest = candidate;
      }
    }

    return latest ?? now;
  }

  double _calculateProgress(IrrigationScheduleModel schedule) {
    final now = DateTime.now();
    final previous = _previousOccurrence(schedule);
    final next = _nextOccurrence(schedule);

    final totalSeconds = next.difference(previous).inSeconds;
    final passedSeconds = now.difference(previous).inSeconds;

    if (totalSeconds <= 0) return 0.12;

    double realProgress = passedSeconds / totalSeconds;
    realProgress = realProgress.clamp(0, 1);

    final easedProgress = math.sqrt(realProgress);
    const double minVisibleProgress = 0.12;
    final visualProgress = minVisibleProgress + (easedProgress * (1 - minVisibleProgress));

    return visualProgress.clamp(0.12, 1.0);
  }

  List<int> _soilRawList(dynamic telemetry) {
    final rawList = telemetry?.soilRaw;
    if (rawList == null) return const [];
    return List<int>.from(rawList);
  }

  double? _soilRawAverage(dynamic telemetry) {
    final rawList = _soilRawList(telemetry);
    if (rawList.isEmpty) return null;
    final total = rawList.fold<int>(0, (sum, item) => sum + item);
    return total / rawList.length;
  }

  double? _soilPercent(dynamic telemetry) {
    final raw = _soilRawAverage(telemetry);
    if (raw == null) return null;

    final percent = ((_soilDryRaw - raw) / (_soilDryRaw - _soilWetRaw)) * 100.0;
    return percent.clamp(0.0, 100.0);
  }

  String _soilValue(dynamic telemetry) {
    final percent = _soilPercent(telemetry);
    if (percent == null) return '--';
    return '${percent.toStringAsFixed(0)}%';
  }

  String _soilStatus(dynamic telemetry) {
    final percent = _soilPercent(telemetry);
    if (percent == null) return '--';

    if (percent <= 20) return 'VERY DRY';
    if (percent <= 40) return 'DRY';
    if (percent <= 60) return 'MOIST';
    if (percent <= 80) return 'WET';
    return 'VERY WET';
  }

  double _soilProgress(dynamic telemetry) {
    final percent = _soilPercent(telemetry);
    if (percent == null) return 0.12;
    return (percent / 100).clamp(0.12, 1.0);
  }

  Color _soilColor(dynamic telemetry) {
    final percent = _soilPercent(telemetry);
    if (percent == null) return _neutralColor;

    if (percent <= 20) return const Color(0xFFEF4444);
    if (percent <= 40) return const Color(0xFFF97316);
    if (percent <= 80) return const Color(0xFF3B82F6);
    return const Color(0xFF60A5FA);
  }

  String _tankValue(dynamic telemetry) {
    final volume = telemetry?.volume;
    if (volume == null) return '--';
    return '${(volume as num).toDouble().toStringAsFixed(0)}L';
  }

  String _tankStatus(dynamic telemetry) => telemetry?.tankStatus ?? '--';

  double _tankProgress(dynamic telemetry) {
    final level = telemetry?.level;
    if (level == null) return 0.12;
    return (((level as num).toDouble()) / 100).clamp(0.12, 1.0);
  }

  Color _tankColor(dynamic telemetry) {
    final status = (telemetry?.tankStatus ?? '').toString().toUpperCase();
    final level = telemetry?.level;

    if (status == 'UNKNOWN') return const Color(0xFF94A3B8);
    if (level == null) return _neutralColor;

    final levelValue = (level as num).toDouble();

    if (levelValue < 25) return const Color(0xFFEF4444);
    if (levelValue < 60) return const Color(0xFF60A5FA);
    return const Color(0xFF0284C7);
  }

  String _pondValue(dynamic telemetry) {
    final volume = telemetry?.pondVolume;
    if (volume == null) return '--';
    return '${(volume as num).toDouble().toStringAsFixed(0)}L';
  }

  String _pondStatus(dynamic telemetry) => telemetry?.pondStatus ?? '--';

  double _pondProgress(dynamic telemetry) {
    final level = telemetry?.pondLevel;
    if (level == null) return 0.12;
    return (((level as num).toDouble()) / 100).clamp(0.12, 1.0);
  }

  Color _pondColor(dynamic telemetry) {
    final status = (telemetry?.pondStatus ?? '').toString().toUpperCase();
    final level = telemetry?.pondLevel;

    if (status == 'UNKNOWN') return const Color(0xFF94A3B8);
    if (level == null) return _neutralColor;

    final levelValue = (level as num).toDouble();

    if (levelValue < 25) return const Color(0xFFEF4444);
    if (levelValue < 60) return const Color(0xFF60A5FA);
    return const Color(0xFF0369A1);
  }

  String _phValue(dynamic telemetry) {
    final ph = telemetry?.ph;
    if (ph == null) return '--';
    return '${(ph as num).toDouble().toStringAsFixed(1)} pH';
  }

  String _phStatus(dynamic telemetry) {
    final ph = telemetry?.ph;
    if (ph == null) return '--';

    final phValue = (ph as num).toDouble();

    if (phValue < 5.5) return 'Acidic';
    if (phValue <= 7.5) return 'Good';
    return 'Alkaline';
  }

  double _phProgress(dynamic telemetry) {
    final ph = telemetry?.ph;
    if (ph == null) return 0.12;
    return (((ph as num).toDouble()) / 14).clamp(0.12, 1.0);
  }

  Color _phColor(dynamic telemetry) {
    final ph = telemetry?.ph;
    if (ph == null) return _neutralColor;

    final value = (ph as num).toDouble();

    if (value < 5.5) return const Color(0xFFEF4444);
    if (value <= 7.5) return const Color(0xFF22C55E);
    if (value <= 9.0) return const Color(0xFF3B82F6);
    return const Color(0xFF7C3AED);
  }

  String _creatorLabel(String createdBy) {
    final clean = createdBy.trim();
    if (clean.isEmpty) return 'Shared schedule';

    final firstName = clean.split(' ').first.trim();
    if (firstName.isEmpty) return 'Shared schedule';

    return 'Set by $firstName';
  }

  // ===== Rain helpers (clean UI) =====

  String _formatRemainingHours(double hours) {
    if (hours <= 0) return 'Now';

    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h == 0) return 'in ${m}m';
    if (m == 0) return 'in ${h}h';
    return 'in ${h}h ${m}m';
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  // title
  String _rainNowData(dynamic telemetry) {
    if (telemetry == null) return '--';
    final mm = _toDouble(telemetry.rain3h);
    final pop = _toDouble(telemetry.pop3);
    return '3h ${mm.toStringAsFixed(1)} mm • ${pop.toStringAsFixed(0)}%';
  }

  // value
  String _rainRemaining(dynamic telemetry) {
    if (telemetry == null) return '--';
    return _formatRemainingHours(_toDouble(telemetry.reta));
  }

  // status
  String _rainActionStatus(dynamic telemetry) {
    if (telemetry == null) return '--';

    final raw = '${telemetry.iwx} ${telemetry.wxsd}'.toLowerCase();
    final popMax = math.max(
      _toDouble(telemetry.pop3),
      math.max(_toDouble(telemetry.pop6), _toDouble(telemetry.pop12)),
    );
    final mmMax = math.max(
      _toDouble(telemetry.rain3h),
      math.max(_toDouble(telemetry.rain6h), _toDouble(telemetry.rain12h)),
    );

    if (raw.contains('skip') || popMax >= 85 || mmMax >= 8) return 'Skip';
    if (raw.contains('short') || raw.contains('delay') || popMax >= 60 || mmMax >= 4) {
      return 'Delay';
    }
    return 'Allow';
  }

  double _rainProgress(dynamic telemetry) {
    if (telemetry == null) return 0.12;
    final etaHours = _toDouble(telemetry.reta);
    if (etaHours <= 0) return 1.0;
    final normalized = 1 - (etaHours / 24.0);
    return normalized.clamp(0.12, 1.0);
  }

  Color _rainColor(dynamic telemetry) {
    final status = _rainActionStatus(telemetry);
    if (status == 'Skip') return _criticalColor;
    if (status == 'Delay') return _warningColor;
    return _accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    final irrigation = context.watch<IrrigationController>();
    final session = context.watch<DeviceSessionController>();
    final telemetry = irrigation.telemetry;
    final pairCode = session.pairedCode;

    final width = MediaQuery.of(context).size.width;

    final double childAspectRatio = width >= 1200
        ? 1.35
        : width >= 900
        ? 1.18
        : width >= 700
        ? 0.98
        : 0.82;

    if (!session.isPaired) {
      return const UnpairedDeviceCard();
    }

    if (session.isPaired && telemetry == null) {
      return WaitingForDeviceCard(
        pairedCode: session.pairedCode ?? '--',
        role: session.role ?? 'viewer',
      );
    }

    if (pairCode == null || pairCode.isEmpty) {
      return const UnpairedDeviceCard();
    }

    final IrrigationScheduleService scheduleService = IrrigationScheduleService();

    return StreamBuilder<IrrigationScheduleModel?>(
      stream: scheduleService.getNearestSchedule(pairCode: pairCode),
      builder: (context, snapshot) {
        String title = 'Latest Irrigation';
        String value = '--';
        String status = 'No schedule';
        String category = 'Shared schedule';
        double progress = 0.12;

        Color statusColor = _neutralColor;
        Color progressColor = _neutralColor;

        if (snapshot.hasData && snapshot.data != null) {
          final schedule = snapshot.data!;
          final next = _nextOccurrence(schedule);
          final diff = next.difference(DateTime.now());

          title = schedule.note.trim().isEmpty ? 'Latest irrigation' : schedule.note.trim();

          value = _formatTime(schedule.hour, schedule.minute);
          status = _formatCountdown(diff);
          category = _creatorLabel(schedule.createdBy);
          progress = _calculateProgress(schedule);

          statusColor = _primaryColor;
          progressColor = _primaryColor;
        }

        final soilColor = _soilColor(telemetry);
        final tankColor = _tankColor(telemetry);
        final pondColor = _pondColor(telemetry);
        final phColor = _phColor(telemetry);
        final rainColor = _rainColor(telemetry);

        final allCards = <CardFilter, ConnectedDeviceItemCard>{
          CardFilter.soil: ConnectedDeviceItemCard(
            category: 'Soil Moisture',
            title: 'Current Soil Hydration',
            value: _soilValue(telemetry),
            status: _soilStatus(telemetry),
            statusColor: soilColor,
            imagePath: 'assets/images/sensor_img/soil_moisture.webp',
            progressColor: soilColor,
            progress: _soilProgress(telemetry),
          ),
          CardFilter.tank: ConnectedDeviceItemCard(
            category: 'Rainwater Source',
            title: 'Tank Level',
            value: _tankValue(telemetry),
            status: _tankStatus(telemetry),
            statusColor: tankColor,
            imagePath: 'assets/images/IBC_tank.webp',
            progressColor: tankColor,
            progress: _tankProgress(telemetry),
          ),
          CardFilter.pond: ConnectedDeviceItemCard(
            category: 'Backup Source',
            title: 'Fish Pond Level',
            value: _pondValue(telemetry),
            status: _pondStatus(telemetry),
            statusColor: pondColor,
            imagePath: 'assets/images/pond-1.webp',
            progressColor: pondColor,
            progress: _pondProgress(telemetry),
          ),
          CardFilter.ph: ConnectedDeviceItemCard(
            category: 'Ideal for crops',
            title: 'pH Level',
            value: _phValue(telemetry),
            status: _phStatus(telemetry),
            statusColor: phColor,
            imagePath: 'assets/images/sensor_img/ph_level.webp',
            progressColor: phColor,
            progress: _phProgress(telemetry),
          ),
          CardFilter.rain: ConnectedDeviceItemCard(
            category: 'Upcoming Rain',
            title: _rainNowData(telemetry),
            value: _rainRemaining(telemetry),
            status: _rainActionStatus(telemetry),
            statusColor: rainColor,
            imagePath: 'assets/images/up_rain.webp',
            progressColor: rainColor,
            progress: _rainProgress(telemetry),
          ),
          CardFilter.schedule: ConnectedDeviceItemCard(
            category: category,
            title: title,
            value: value,
            status: status,
            statusColor: statusColor,
            imagePath: 'assets/images/sensor_img/set_time.webp',
            progressColor: progressColor,
            progress: progress,
          ),
        };

        final bool isAll = _selectedFilter == CardFilter.all;
        final items = isAll ? allCards.values.toList() : [allCards[_selectedFilter]!];

        final List<Widget> gridItems = isAll
            ? items
            : <Widget>[
          items.first,
          const SizedBox.shrink(),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(),
            const SizedBox(height: 12),
            Container(
              key: _cardsGridKey,
              child: GridView.builder(
                itemCount: gridItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) => gridItems[index],
              ),
            ),
          ],
        );
      },
    );
  }
}