// lib/utils/current_weather_icon_util.dart

class CurrentWeatherIconUtil {
  static const Duration _philippineOffset = Duration(hours: 8);

  /// Returns the asset path of the current weather icon.
  /// Day/night is based on Philippine time, not the API icon suffix.
  static String getWeatherIcon(String iconCode, {DateTime? currentTime}) {
    final nowInPH = currentTime != null
        ? currentTime.toUtc().add(_philippineOffset)
        : DateTime.now().toUtc().add(_philippineOffset);

    final hour = nowInPH.hour;
    final bool isDay = hour >= 6 && hour < 18;

    // Remove the API day/night suffix (d/n)
    final weatherCode = iconCode.replaceAll(RegExp(r'[dn]$'), '');

    switch (weatherCode) {
      case '01':
        return 'assets/icons/sunny.webp';

      case '02':
        return isDay
            ? 'assets/icons/partly_cloudy_day.webp'
            : 'assets/icons/partly_cloudy_night.webp';

      case '03':
        return 'assets/icons/scattered_clouds.webp';

      case '04':
        return 'assets/icons/broken_clouds.webp';

      case '09':
        return 'assets/icons/light_rain.webp';

      case '10':
        return 'assets/icons/rain.webp';

      case '11':
        return 'assets/icons/thunderstorm.webp';

      case '13':
        return 'assets/icons/snow.webp';

      case '50':
        return 'assets/icons/mist.webp';

      default:
        return isDay
            ? 'assets/icons/partly_cloudy_day.webp'
            : 'assets/icons/partly_cloudy_night.webp';
    }
  }
}