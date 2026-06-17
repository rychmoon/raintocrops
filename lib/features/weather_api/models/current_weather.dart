class CurrentWeatherModel {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final int pressure;
  final int timestamp;

  const CurrentWeatherModel({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.pressure,
    required this.timestamp,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List?;

    return CurrentWeatherModel(
      cityName: json['name'] ?? '',

      temperature: (json['main']?['temp'] ?? 0).toDouble(),

      feelsLike: (json['main']?['feels_like'] ?? 0).toDouble(),

      humidity: json['main']?['humidity'] ?? 0,

      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),

      description: weatherList != null && weatherList.isNotEmpty
          ? weatherList[0]['description'] ?? ''
          : '',

      icon: weatherList != null && weatherList.isNotEmpty
          ? weatherList[0]['icon'] ?? ''
          : '',

      pressure: json['main']?['pressure'] ?? 0,

      timestamp: json['dt'] ?? 0,
    );
  }

  /// Capitalized weather description
  String get formattedDescription {
    if (description.isEmpty) return '';
    return description[0].toUpperCase() + description.substring(1);
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'icon': icon,
      'pressure': pressure,
      'timestamp': timestamp,
    };
  }
}