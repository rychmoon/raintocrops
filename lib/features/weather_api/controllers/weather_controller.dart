import 'package:flutter/material.dart';
import '/features/weather_api/models/weather_bundle.dart';
import '/features/weather_api/services/weather_service.dart';

class WeatherController extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  WeatherBundleModel? weather;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchWeather({
    required double lat,
    required double lon,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _weatherService.getWeatherBundle(
        lat: lat,
        lon: lon,
      );

      weather = result;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWeather({
    required double lat,
    required double lon,
  }) async {
    try {
      final result = await _weatherService.getWeatherBundle(
        lat: lat,
        lon: lon,
      );

      weather = result;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}