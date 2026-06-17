import 'dart:async';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

import '/features/weather_api/models/forecast.dart';
import '/features/weather_api/utils/forecast_icon_util.dart';

class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics().applyTo(
      const ClampingScrollPhysics(),
    );
  }
}

class TodayForecastCard extends StatefulWidget {
  final ForecastModel forecast;

  const TodayForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  State<TodayForecastCard> createState() =>
      _TodayForecastCardsState();
}

class _TodayForecastCardsState
    extends State<TodayForecastCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // refresh highlight every few seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
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

  @override
  Widget build(BuildContext context) {
    final List<ForecastItemModel> forecastList =
    widget.forecast.items.take(5).toList();

    if (forecastList.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No forecast available',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final roundedHour = (now.hour ~/ 3) * 3;

    int currentIndex = -1;

    for (int i = 0; i < forecastList.length; i++) {
      final itemTime = _parseForecastTime(forecastList[i]);

      if (itemTime.year == now.year &&
          itemTime.month == now.month &&
          itemTime.day == now.day &&
          itemTime.hour == roundedHour) {
        currentIndex = i;
        break;
      }
    }

    return SizedBox(
      height: 140,
      child: ScrollConfiguration(
        behavior: const _SmoothScrollBehavior(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: forecastList.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = forecastList[index];
            final itemTime = _parseForecastTime(item);

            final time = DateFormat.jm().format(itemTime);
            final temp = "${item.temperature.toStringAsFixed(0)}°";
            final pop = (item.pop * 100).toStringAsFixed(0);
            final iconPath = CurrentWeatherIconUtil.getWeatherIcon(
              item.icon,
              currentTime: itemTime,
            );

            return _ForecastBox(
              time: time,
              iconPath: iconPath,
              temp: temp,
              pop: pop,
              isCurrent: index == currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class _ForecastBox extends StatelessWidget {
  final String time;
  final String iconPath;
  final String temp;
  final String pop;
  final bool isCurrent;

  const _ForecastBox({
    required this.time,
    required this.iconPath,
    required this.temp,
    required this.pop,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final Color txt = isCurrent ? Colors.white : Colors.black;

    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrent ? null : const Color(0xFFFFFFFF),
        gradient: isCurrent
            ? const LinearGradient(
          colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFAED4FF)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: txt,
            ),
          ),

          Image.asset(
            iconPath,
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),

          Text(
            temp,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: txt,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Bootstrap.droplet,
                size: 10,
                color: isCurrent ? Colors.white : Colors.blueGrey,
              ),
              const SizedBox(width: 2),
              Text(
                "$pop%",
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent ? Colors.white : Colors.blueGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}