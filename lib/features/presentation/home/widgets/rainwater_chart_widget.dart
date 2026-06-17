import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/collected_rain_statistics/rain_history_entry.dart';
import '/features/collected_rain_statistics/rain_history_service.dart';
import '/features/irrigation/controller/irrigation_controller.dart';

enum TimeRange { weekly, monthly, yearly }

class RainwaterChartWidget extends StatefulWidget {
  const RainwaterChartWidget({super.key});

  @override
  State<RainwaterChartWidget> createState() => _RainwaterChartWidgetState();
}

class _RainwaterChartWidgetState extends State<RainwaterChartWidget> {
  final RainHistoryService _rainHistoryService = RainHistoryService();

  static const Color usageColor = Color(0xFF22C55E);
  static const Color collectedColor = Color(0xFF03A9F4);

  TimeRange _selectedRange = TimeRange.weekly;
  bool _isLoading = true;
  String? _loadedDeviceId;
  List<RainHistoryEntry> _entries = [];
  Timer? _liveRefreshTimer;

  int _selectedMonthlyYear = DateTime.now().year;
  int _selectedYearlyStartYear = 2026;

  final List<String> _weekdayNames = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _monthlyLabels = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    if (currentYear < 2026) return [2026];
    return List.generate(currentYear - 2026 + 1, (index) => 2026 + index);
  }

  List<int> get _yearlyLabels {
    final currentYear = DateTime.now().year;
    if (_selectedYearlyStartYear > currentYear) return [_selectedYearlyStartYear];
    return List.generate(currentYear - _selectedYearlyStartYear + 1, (index) => _selectedYearlyStartYear + index);
  }

  @override
  void initState() {
    super.initState();
    _startLiveRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  void _startLiveRefresh() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!mounted) return;
      final deviceId = context.read<IrrigationController>().deviceId;
      if (deviceId == null) return;
      await _loadHistory(deviceId, silent: true);
    });
  }

  Future<void> _loadIfNeeded() async {
    final deviceId = context.read<IrrigationController>().deviceId;

    if (deviceId == null) {
      if (!mounted) return;
      setState(() {
        _loadedDeviceId = null;
        _entries = [];
        _isLoading = false;
      });
      return;
    }

    if (_loadedDeviceId == deviceId && !_isLoading) return;
    await _loadHistory(deviceId);
  }

  Future<void> _loadHistory(String deviceId, {bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);

    try {
      final data = await _rainHistoryService.fetchDailyHistory(deviceId: deviceId, limit: 1000);
      if (!mounted) return;

      setState(() {
        _loadedDeviceId = deviceId;
        _entries = data;
        _isLoading = false;

        if (!_availableYears.contains(_selectedMonthlyYear)) _selectedMonthlyYear = DateTime.now().year;
        if (!_availableYears.contains(_selectedYearlyStartYear)) _selectedYearlyStartYear = 2026;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadedDeviceId = deviceId;
        _entries = [];
        _isLoading = false;
      });
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<String> get _rotatedWeeklyLabels {
    final today = DateTime.now();
    final mondayBasedIndex = (today.weekday - 1) % 7;

    return List.generate(7, (index) {
      final labelIndex = (mondayBasedIndex - 6 + index) % 7;
      final safeIndex = labelIndex < 0 ? labelIndex + 7 : labelIndex;
      return _weekdayNames[safeIndex];
    });
  }

  List<FlSpot> _weeklySpots(double Function(RainHistoryEntry e) valueOf) {
    final today = _dateOnly(DateTime.now());
    final byDate = <String, double>{for (final e in _entries) e.dateKey: valueOf(e)};

    return List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final key = _formatDateKey(day);
      return FlSpot(index.toDouble(), byDate[key] ?? 0.0);
    });
  }

  List<FlSpot> _monthlySpots(double Function(RainHistoryEntry e) valueOf) {
    final totals = List<double>.filled(12, 0.0);
    for (final e in _entries) {
      if (e.year == _selectedMonthlyYear && e.month >= 1 && e.month <= 12) {
        totals[e.month - 1] += valueOf(e);
      }
    }
    return List.generate(12, (i) => FlSpot(i.toDouble(), totals[i]));
  }

  List<FlSpot> _yearlySpots(double Function(RainHistoryEntry e) valueOf) {
    final years = _yearlyLabels;
    final totals = <int, double>{for (final y in years) y: 0.0};

    for (final e in _entries) {
      if (totals.containsKey(e.year)) {
        totals[e.year] = (totals[e.year] ?? 0.0) + valueOf(e);
      }
    }

    return List.generate(years.length, (i) => FlSpot(i.toDouble(), totals[years[i]] ?? 0.0));
  }

  List<FlSpot> _spotsForRange(TimeRange range, double Function(RainHistoryEntry e) valueOf) {
    switch (range) {
      case TimeRange.weekly:
        return _weeklySpots(valueOf);
      case TimeRange.monthly:
        return _monthlySpots(valueOf);
      case TimeRange.yearly:
        return _yearlySpots(valueOf);
    }
  }

  double _xInterval(TimeRange range) {
    switch (range) {
      case TimeRange.weekly:
        return 1;
      case TimeRange.monthly:
        return 2;
      case TimeRange.yearly:
        return 1;
    }
  }

  double _maxX(TimeRange range) {
    switch (range) {
      case TimeRange.weekly:
        return 6;
      case TimeRange.monthly:
        return 11;
      case TimeRange.yearly:
        return (_yearlyLabels.length - 1).toDouble();
    }
  }

  String _bottomLabel(double value) {
    final index = value.toInt();
    switch (_selectedRange) {
      case TimeRange.weekly:
        final labels = _rotatedWeeklyLabels;
        return (index >= 0 && index < labels.length) ? labels[index] : '';
      case TimeRange.monthly:
        return (index >= 0 && index < _monthlyLabels.length) ? _monthlyLabels[index] : '';
      case TimeRange.yearly:
        final years = _yearlyLabels;
        return (index >= 0 && index < years.length) ? years[index].toString() : '';
    }
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final label = _bottomLabel(value);
    if (label.isEmpty) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
      ),
    );
  }

  double _maxYTwoSeries(List<FlSpot> a, List<FlSpot> b) {
    double maxValue = 0;
    for (final s in a) {
      if (s.y > maxValue) maxValue = s.y;
    }
    for (final s in b) {
      if (s.y > maxValue) maxValue = s.y;
    }
    if (maxValue <= 0) return 10;
    return (maxValue * 1.22).ceilToDouble();
  }

  double _sum(List<FlSpot> spots) => spots.fold<double>(0, (sum, s) => sum + s.y);

  String _periodLabelForX(double x) {
    final index = x.toInt();
    switch (_selectedRange) {
      case TimeRange.weekly:
        final labels = _rotatedWeeklyLabels;
        return (index >= 0 && index < labels.length) ? labels[index] : '';
      case TimeRange.monthly:
        return (index >= 0 && index < _monthlyLabels.length) ? '${_monthlyLabels[index]} $_selectedMonthlyYear' : '';
      case TimeRange.yearly:
        final years = _yearlyLabels;
        return (index >= 0 && index < years.length) ? years[index].toString() : '';
    }
  }

  Widget _buildCompactDropdown({
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE7F3), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF4B5563)),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF000000)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const titleStyle = TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF111827));

    switch (_selectedRange) {
      case TimeRange.weekly:
        return const Align(
          alignment: Alignment.centerLeft,
          child: Text('Rainwater Overview', style: titleStyle),
        );
      case TimeRange.monthly:
        return Row(
          children: [
            const Expanded(
              child: Text('Rainwater Overview', style: titleStyle, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 10),
            _buildCompactDropdown(
              value: _selectedMonthlyYear,
              items: _availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedMonthlyYear = v);
              },
            ),
          ],
        );
      case TimeRange.yearly:
        return Row(
          children: [
            const Expanded(
              child: Text('Rainwater Overview', style: titleStyle, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 10),
            _buildCompactDropdown(
              value: _selectedYearlyStartYear,
              items: _availableYears.map((y) => DropdownMenuItem(value: y, child: Text('From $y'))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedYearlyStartYear = v);
              },
            ),
          ],
        );
    }
  }

  Widget _buildTopTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: TimeRange.values.map((range) {
          final isActive = _selectedRange == range;
          final label = range == TimeRange.weekly ? 'WEEK' : range == TimeRange.monthly ? 'MONTH' : 'YEAR';

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _selectedRange = range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w700,
                      color: isActive ? const Color(0xFF03A9F4) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2.5,
                    width: 28,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF03A9F4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightBoxes(List<FlSpot> usageSpots, List<FlSpot> collectedSpots) {
    final usageTotal = _sum(usageSpots);
    final collectedTotal = _sum(collectedSpots);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildInsightCard(
              title: 'Total Usage',
              value: usageTotal,
              unit: 'L',
              subtitle: 'Selected ${_selectedRange.name}', // changed
              icon: Icons.eco_outlined,
              iconColor: usageColor,
              bgTint: usageColor.withOpacity(0.06),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildInsightCard(
              title: 'Total Collected',
              value: collectedTotal,
              unit: 'L',
              subtitle: 'Selected ${_selectedRange.name}', // changed
              icon: Icons.water_drop_outlined,
              iconColor: collectedColor,
              bgTint: collectedColor.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required double value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, bgTint],
        ),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<FlSpot> usageSpots, List<FlSpot> collectedSpots) {
    final deviceId = context.watch<IrrigationController>().deviceId;

    if (deviceId == null) {
      return _buildEmptyCard(
        title: 'No device connected',
        subtitle: 'Connect a device first to view rainwater history.',
      );
    }

    if (_isLoading) return _buildLoadingCard();

    final xInterval = _xInterval(_selectedRange);
    final maxY = _maxYTwoSeries(usageSpots, collectedSpots);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          SizedBox(
            height: 235,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: _maxX(_selectedRange),
                minY: 0,
                maxY: maxY,
                clipData: FlClipData.none(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 30,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tooltipMargin: 10,
                    getTooltipItems: (touchedSpots) {
                      if (touchedSpots.isEmpty) return [];

                      final period = _periodLabelForX(touchedSpots.first.x);

                      double usage = 0;
                      double collected = 0;
                      for (final s in touchedSpots) {
                        if (s.barIndex == 0) usage = s.y;
                        if (s.barIndex == 1) collected = s.y;
                      }

                      return List.generate(touchedSpots.length, (i) {
                        if (i == 0) {
                          return LineTooltipItem(
                            '$period\n'
                                'Usage: ${usage.toStringAsFixed(1)} L\n'
                                'Collected: ${collected.toStringAsFixed(1)} L',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          );
                        }
                        return const LineTooltipItem('', TextStyle(fontSize: 0));
                      });
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 10 ? 2 : (maxY / 5),
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFE9EEF5),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: xInterval,
                      reservedSize: 44,
                      getTitlesWidget: _buildBottomTitle,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY <= 10 ? 2 : (maxY / 5),
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                        style: const TextStyle(
                          fontSize: 9.8,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: usageSpots,
                    isCurved: true,
                    color: usageColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.0,
                        color: usageColor,
                        strokeWidth: 1.2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: usageColor.withValues(alpha: 0.05),
                    ),
                  ),
                  LineChartBarData(
                    spots: collectedSpots,
                    isCurved: true,
                    color: collectedColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.0,
                        color: collectedColor,
                        strokeWidth: 1.2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 14, height: 3, decoration: BoxDecoration(color: usageColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Usage', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(width: 14),
              Container(width: 14, height: 3, decoration: BoxDecoration(color: collectedColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Collected', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
    );
  }

  Widget _buildEmptyCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.water_drop_outlined, size: 40, color: Colors.lightBlue.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usageSpots = _spotsForRange(_selectedRange, (e) => e.collectedLiters);
    final collectedSpots = _spotsForRange(_selectedRange, (e) => e.collectedRainLiters);

    return Column(
      children: [
        _buildTopTabs(),
        _buildInsightBoxes(usageSpots, collectedSpots),
        const SizedBox(height: 10),
        _buildBody(usageSpots, collectedSpots),
      ],
    );
  }
}