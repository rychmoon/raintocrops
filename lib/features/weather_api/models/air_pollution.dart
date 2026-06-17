class AirPollutionModel {
  final int aqi;
  final double pm2_5;
  final double pm10;
  final double co;
  final double no2;
  final double o3;
  final int timestamp;

  const AirPollutionModel({
    required this.aqi,
    required this.pm2_5,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.o3,
    required this.timestamp,
  });

  factory AirPollutionModel.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List? ?? [];

    if (list.isEmpty) {
      return const AirPollutionModel(
        aqi: 0,
        pm2_5: 0,
        pm10: 0,
        co: 0,
        no2: 0,
        o3: 0,
        timestamp: 0,
      );
    }

    final data = list.first;

    return AirPollutionModel(
      aqi: data['main']?['aqi'] ?? 0,
      pm2_5: (data['components']?['pm2_5'] ?? 0).toDouble(),
      pm10: (data['components']?['pm10'] ?? 0).toDouble(),
      co: (data['components']?['co'] ?? 0).toDouble(),
      no2: (data['components']?['no2'] ?? 0).toDouble(),
      o3: (data['components']?['o3'] ?? 0).toDouble(),
      timestamp: data['dt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'pm2_5': pm2_5,
      'pm10': pm10,
      'co': co,
      'no2': no2,
      'o3': o3,
      'timestamp': timestamp,
    };
  }
}