import '/features/weather_api/models/current_weather.dart';
import '/features/weather_api/models/forecast.dart';
import '/features/weather_api/models/air_pollution.dart';

class WeatherBundleModel {
  final CurrentWeatherModel currentWeather;
  final ForecastModel forecast;
  final AirPollutionModel airPollution;

  const WeatherBundleModel({
    required this.currentWeather,
    required this.forecast,
    required this.airPollution,
  });

  factory WeatherBundleModel.fromMap(Map<String, dynamic> map) {
    return WeatherBundleModel(
      currentWeather: CurrentWeatherModel.fromJson(
        map['current'] as Map<String, dynamic>,
      ),
      forecast: ForecastModel.fromJson(
        map['forecast'] as Map<String, dynamic>,
      ),
      airPollution: AirPollutionModel.fromJson(
        map['air'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWeather': currentWeather.toJson(),
      'forecast': forecast.toJson(),
      'airPollution': airPollution.toJson(),
    };
  }
}