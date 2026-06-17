import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get mqttHost => dotenv.env['MQTT_HOST'] ?? '';
  static int get mqttPort =>
      int.tryParse(dotenv.env['MQTT_PORT'] ?? '8883') ?? 8883;
  static String get mqttUser => dotenv.env['MQTT_USER'] ?? '';
  static String get mqttPass => dotenv.env['MQTT_PASS'] ?? '';
}