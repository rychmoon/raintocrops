import 'dart:async';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '/features/weather_api/models/forecast.dart';
import '/features/weather_api/utils/forecast_icon_util.dart';

class FiveDayForecast extends StatefulWidget {
  final ForecastModel forecast;

  const FiveDayForecast({
    super.key,
    required this.forecast,
  });

  @override
  State<FiveDayForecast> createState() => _FiveDayForecastState();
}

class _FiveDayForecastState extends State<FiveDayForecast> {
  Timer? _timer;
  int _selectedIndex = 0;

  static const Color _pageBg = Color(0xFFF6F6F6);
  static const Color _mainText = Color(0xFF111827);
  static const Color _subText = Color(0xFF6B7280);
  static const Color _softTile = Color(0xFFFBFBFB);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _parseForecastTime(ForecastItemModel item) {
    try {
      return DateTime.parse(item.dateText);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(item.timestamp * 1000);
    }
  }

  String _formatWeatherDescription(ForecastItemModel item) {
    final text = item.description.trim();
    if (text.isEmpty) return 'Forecast';

    return text
        .split(' ')
        .map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    })
        .join(' ');
  }

  List<_DailyForecastSummary> _buildFiveDayForecast() {
    final now = DateTime.now();
    final Map<String, List<ForecastItemModel>> grouped = {};

    for (final item in widget.forecast.items) {
      final date = _parseForecastTime(item);
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final List<_DailyForecastSummary> result = [];

    for (final key in sortedKeys) {
      final items = grouped[key]!;
      if (items.isEmpty) continue;

      final dayDate = _parseForecastTime(items.first);
      final onlyDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final todayDate = DateTime(now.year, now.month, now.day);

      if (onlyDate.isBefore(todayDate)) continue;

      double minTemp = items.first.temperature;
      double maxTemp = items.first.temperature;
      double rainChance = 0;
      double rainVolume = 0;
      ForecastItemModel representative = items.first;
      Duration closestToMidday = const Duration(days: 999);

      for (final item in items) {
        if (item.temperature < minTemp) minTemp = item.temperature;
        if (item.temperature > maxTemp) maxTemp = item.temperature;
        if (item.pop > rainChance) rainChance = item.pop;
        rainVolume += item.rainVolume;

        final itemTime = _parseForecastTime(item);
        final midday = DateTime(
          itemTime.year,
          itemTime.month,
          itemTime.day,
          12,
        );

        final diff = itemTime.difference(midday).abs();
        if (diff < closestToMidday) {
          closestToMidday = diff;
          representative = item;
        }
      }

      result.add(
        _DailyForecastSummary(
          date: onlyDate,
          minTemp: minTemp,
          maxTemp: maxTemp,
          rainChance: rainChance,
          rainVolume: rainVolume,
          icon: representative.icon,
          description: _formatWeatherDescription(representative),
        ),
      );

      if (result.length == 5) break;
    }

    return result;
  }

  String _dayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    if (target == tomorrow) return 'Tomorrow';
    return DateFormat('EEEE').format(date);
  }

  String _shortDayTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    return DateFormat('EEEE').format(date);
  }

  String _dateLabel(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  String _contextDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'today';
    if (target == tomorrow) return 'tomorrow';
    return 'on ${DateFormat('EEEE').format(date)}';
  }

  String _rainVolumeLabel(double value) {
    if (value <= 0) return '0 mm';
    return '${value.toStringAsFixed(1)} mm';
  }

  _WeatherPalette _paletteFor(_DailyForecastSummary day) {
    final desc = day.description.toLowerCase();
    final icon = day.icon.toLowerCase();

    if (desc.contains('thunder') || desc.contains('storm')) {
      return const _WeatherPalette(
        start: Color(0xFF4B5563),
        end: Color(0xFF1F2937),
        accent: Color(0xFFCBD5E1),
        chipBg: Color(0x26FFFFFF),
        chipText: Colors.white,
      );
    }

    if (desc.contains('rain') ||
        desc.contains('drizzle') ||
        icon.contains('09') ||
        icon.contains('10')) {
      return const _WeatherPalette(
        start: Color(0xFF5B86B3),
        end: Color(0xFF2F5D8A),
        accent: Color(0xFFDCEEFF),
        chipBg: Color(0x26FFFFFF),
        chipText: Colors.white,
      );
    }

    if (desc.contains('cloud')) {
      return const _WeatherPalette(
        start: Color(0xFF7C83A3),
        end: Color(0xFF4C5C87),
        accent: Color(0xFFF3F4F6),
        chipBg: Color(0x26FFFFFF),
        chipText: Colors.white,
      );
    }

    if (desc.contains('snow') || icon.contains('13')) {
      return const _WeatherPalette(
        start: Color(0xFF78B7FF),
        end: Color(0xFF4E8FE2),
        accent: Color(0xFFF8FBFF),
        chipBg: Color(0x26FFFFFF),
        chipText: Colors.white,
      );
    }

    return const _WeatherPalette(
      start: Color(0xFFFFC533),
      end: Color(0xFFFF9F1C),
      accent: Color(0xFFFFF3D6),
      chipBg: Color(0x26FFFFFF),
      chipText: Colors.white,
    );
  }

  String _rainInsight(_DailyForecastSummary day) {
    final percent = day.rainChance * 100;
    final volume = day.rainVolume;
    final label = _contextDayLabel(day.date);

    if (percent < 15 && volume < 0.3) {
      return 'No rain expected $label';
    } else if (percent < 40 && volume < 1.5) {
      return 'Light rain possible $label';
    } else if (percent < 70 || volume < 5) {
      return 'Rain likely later $label';
    } else {
      return 'Heavy rain expected $label';
    }
  }


  String _irrigationHint(_DailyForecastSummary day) {
    final percent = day.rainChance * 100;
    final volume = day.rainVolume;

    if (percent < 20 && volume < 1) {
      return 'Good day for watering.';
    } else if (percent < 50 && volume < 3) {
      return 'Monitor soil moisture before irrigating.';
    } else if (percent < 70 && volume < 6) {
      return 'You may reduce irrigation if soil is still wet.';
    } else {
      return 'Consider skipping irrigation due to expected rain.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyForecasts = _buildFiveDayForecast();

    if (dailyForecasts.isEmpty) {
      return Container(
        color: _pageBg,
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'No 5-day forecast available',
            style: TextStyle(
              fontSize: 14,
              color: _subText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (_selectedIndex >= dailyForecasts.length) {
      _selectedIndex = 0;
    }

    final selected = dailyForecasts[_selectedIndex];
    final palette = _paletteFor(selected);

    final selectedIconPath = CurrentWeatherIconUtil.getWeatherIcon(
      selected.icon,
      currentTime: selected.date,
    );

    final rainPercent = (selected.rainChance * 100).toStringAsFixed(0);

    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.start, palette.end],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: palette.end.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dayTitle(selected.date),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dateLabel(selected.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '${selected.maxTemp.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  fontSize: 54,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selected.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _HeroChip(
                                    icon: FontAwesome.temperature_low_solid,
                                    label:
                                    'Low ${selected.minTemp.toStringAsFixed(0)}°',
                                    bg: palette.chipBg,
                                    textColor: palette.chipText,
                                  ),
                                  _HeroChip(
                                    icon: FontAwesome.cloud_rain_solid,
                                    label: '$rainPercent% rain',
                                    bg: palette.chipBg,
                                    textColor: palette.chipText,
                                  ),
                                  _HeroChip(
                                    icon: FontAwesome.droplet_solid,
                                    label: _rainVolumeLabel(selected.rainVolume),
                                    bg: palette.chipBg,
                                    textColor: palette.chipText,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: Image.asset(
                            selectedIconPath,
                            height: 128,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            selected.rainChance >= 0.4
                                ? FontAwesome.cloud_showers_heavy_solid
                                : FontAwesome.circle_info_solid,
                            size: 16,
                            color: palette.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rainInsight(selected),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _irrigationHint(selected),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.84),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next 5 days',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'See what to expect in the coming days.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),


              ListView.separated(
                itemCount: dailyForecasts.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final day = dailyForecasts[index];
                  final isSelected = index == _selectedIndex;

                  final iconPath = CurrentWeatherIconUtil.getWeatherIcon(
                    day.icon,
                    currentTime: day.date,
                  );

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.lightBlue.shade400 : _softTile,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Colors.lightBlue.shade400
                              : const Color(0xFFEAECEF),
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.lightBlue.shade200.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            iconPath,
                            height: 34,
                            width: 34,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _shortDayTitle(day.date),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : _mainText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  day.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.92)
                                        : _subText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(day.rainChance * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : _mainText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _rainVolumeLabel(day.rainVolume),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.88)
                                      : _subText,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 14),

                          Text(
                            '${day.maxTemp.toStringAsFixed(0)}°',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : _mainText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color textColor;

  const _HeroChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyForecastSummary {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final double rainChance;
  final double rainVolume;
  final String icon;
  final String description;

  _DailyForecastSummary({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.rainChance,
    required this.rainVolume,
    required this.icon,
    required this.description,
  });
}

class _WeatherPalette {
  final Color start;
  final Color end;
  final Color accent;
  final Color chipBg;
  final Color chipText;

  const _WeatherPalette({
    required this.start,
    required this.end,
    required this.accent,
    required this.chipBg,
    required this.chipText,
  });
}