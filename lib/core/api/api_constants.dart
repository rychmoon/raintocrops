import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/';

  static const String currentWeather = 'weather';
  static const String forecast = 'forecast';
  static const String airPollution = 'air_pollution';

  static const String units = 'metric';

  static String get apiKey {
    final key = dotenv.env['OPENWEATHER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENWEATHER_API_KEY not found in .env');
    }
    return key;
  }
}