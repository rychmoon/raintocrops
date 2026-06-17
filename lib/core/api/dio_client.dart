import 'package:dio/dio.dart';
import '/core/api/api_constants.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      queryParameters: {
        "appid": ApiConstants.apiKey,
        "units": ApiConstants.units,
      },
    ),
  );

  static Dio get instance => _dio;
}