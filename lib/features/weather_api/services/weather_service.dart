import 'package:dio/dio.dart';
import '/core/api/api_constants.dart';
import '/core/api/dio_client.dart';
import '/features/weather_api/models/current_weather.dart';
import '/features/weather_api/models/forecast.dart';
import '/features/weather_api/models/air_pollution.dart';
import '/features/weather_api/models/weather_bundle.dart';

class WeatherService {
  final Dio _dio = DioClient.instance;

  Future<CurrentWeatherModel> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.currentWeather,
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );

      return CurrentWeatherModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, 'current weather'));
    } catch (e) {
      throw Exception('Failed to fetch current weather: $e');
    }
  }

  Future<ForecastModel> getForecast({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.forecast,
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );

      return ForecastModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, 'forecast'));
    } catch (e) {
      throw Exception('Failed to fetch forecast: $e');
    }
  }

  Future<AirPollutionModel> getAirPollution({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.airPollution,
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );

      return AirPollutionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, 'air pollution'));
    } catch (e) {
      throw Exception('Failed to fetch air pollution: $e');
    }
  }

  Future<WeatherBundleModel> getWeatherBundle({
    required double lat,
    required double lon,
  }) async {
    try {
      final results = await Future.wait([
        getCurrentWeather(lat: lat, lon: lon),
        getForecast(lat: lat, lon: lon),
        getAirPollution(lat: lat, lon: lon),
      ]);

      return WeatherBundleModel(
        currentWeather: results[0] as CurrentWeatherModel,
        forecast: results[1] as ForecastModel,
        airPollution: results[2] as AirPollutionModel,
      );
    } catch (e) {
      throw Exception('Failed to fetch weather bundle: $e');
    }
  }

  String _handleDioError(DioException e, String source) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout while fetching $source.';
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout while fetching $source.';
    }

    if (e.type == DioExceptionType.sendTimeout) {
      return 'Send timeout while fetching $source.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection while fetching $source.';
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 401) {
        return 'Unauthorized request. Check your OpenWeather API key.';
      }

      if (statusCode == 404) {
        return 'Weather endpoint not found.';
      }

      if (statusCode == 429) {
        return 'Too many requests. Please try again later.';
      }

      if (data is Map<String, dynamic> && data['message'] != null) {
        return 'Failed to fetch $source: ${data['message']}';
      }

      return 'Failed to fetch $source. Status code: $statusCode';
    }

    return 'Unexpected error while fetching $source.';
  }
}