import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '/features/weather_api/models/current_weather.dart';
import '/features/weather_api/utils/current_weather_util.dart';
import '/features/weather_api/models/air_pollution.dart';

class CurrentWeatherCard extends StatelessWidget {
  final CurrentWeatherModel currentWeather;
  final AirPollutionModel airPollution;
  final String? weatherAssetIcon;

  const CurrentWeatherCard({
    super.key,
    required this.currentWeather,
    required this.airPollution,
    this.weatherAssetIcon,
  });

  String get airQualityLabel {
    switch (airPollution.aqi) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return '-';
    }
  }

  String get formattedTemperature =>
      '${currentWeather.temperature.toStringAsFixed(0)}°C';

  String get formattedWind =>
      '${currentWeather.windSpeed.toStringAsFixed(0)} km/h';

  String get formattedHumidity => '${currentWeather.humidity}%';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3A7BD5),
            Color(0xFF00D2FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP CONTENT ONLY
              Padding(
                padding: const EdgeInsets.only(right: 95),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.location_outline,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Quezon CIty Now',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTemperature,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentWeather.formattedDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              /// FULL WIDTH WEATHER DETAILS
              Row(
                children: [
                  Expanded(
                    child: _GlassInfoBox(
                      label: 'Wind',
                      value: formattedWind,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GlassInfoBox(
                      label: 'Humidity',
                      value: formattedHumidity,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GlassInfoBox(
                      label: 'Air Quality',
                      value: airQualityLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// WEATHER ICON
          Positioned(
            right: 10,
            top: -8,
            child: Image.asset(
              weatherAssetIcon ??
                  CurrentWeatherIconUtil.getWeatherIcon(currentWeather.icon),
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassInfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _GlassInfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(58),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}