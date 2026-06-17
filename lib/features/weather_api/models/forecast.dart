class ForecastModel {
  final List<ForecastItemModel> items;

  const ForecastModel({
    required this.items,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List? ?? [];

    return ForecastModel(
      items: list
          .map((item) => ForecastItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'list': items.map((e) => e.toJson()).toList(),
    };
  }
}

class ForecastItemModel {
  final int timestamp;
  final String dateText;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final int pressure;
  final int clouds;
  final double windSpeed;
  final double windGust;
  final String mainWeather;
  final String description;
  final String icon;
  final double pop;
  final double rainVolume;

  const ForecastItemModel({
    required this.timestamp,
    required this.dateText,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.clouds,
    required this.windSpeed,
    required this.windGust,
    required this.mainWeather,
    required this.description,
    required this.icon,
    required this.pop,
    required this.rainVolume,
  });

  factory ForecastItemModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final rain = json['rain'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    final weatherList = (json['weather'] as List?) ?? [];
    final weather = weatherList.isNotEmpty
        ? weatherList.first as Map<String, dynamic>
        : <String, dynamic>{};

    return ForecastItemModel(
      timestamp: json['dt'] ?? 0,
      dateText: json['dt_txt'] ?? '',
      temperature: (main['temp'] ?? 0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      humidity: main['humidity'] ?? 0,
      pressure: main['pressure'] ?? 0,
      clouds: clouds['all'] ?? 0,
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      windGust: (wind['gust'] ?? 0).toDouble(),
      mainWeather: weather['main'] ?? '',
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '',
      pop: (json['pop'] ?? 0).toDouble(),
      rainVolume: (rain['3h'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'dateText': dateText,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'clouds': clouds,
      'windSpeed': windSpeed,
      'windGust': windGust,
      'mainWeather': mainWeather,
      'description': description,
      'icon': icon,
      'pop': pop,
      'rainVolume': rainVolume,
    };
  }
}