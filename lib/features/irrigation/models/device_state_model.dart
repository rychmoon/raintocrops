class DeviceStateModel {
  final String id;

  final bool irrigationRunning; // ir
  final String source; // src
  final String waterSource; // wsrc

  final bool manual; // man
  final bool autoSoil; // asoil
  final bool scheduleEnabled; // sch
  final bool strongRain; // wx
  final bool phBlocked; // phb

  // Tank
  final String tank; // tank
  final double level; // lvl

  // Pond
  final String pondTank; // ptank
  final double pondLevel; // plvl

  // Compatibility
  final bool fill; // fill
  final bool rain; // rain
  final bool pond; // pond

  // New overflow fields
  final bool overflow; // ovf
  final String overflowTarget; // ovt

  final int remainingSec; // rem

  const DeviceStateModel({
    required this.id,
    required this.irrigationRunning,
    required this.source,
    required this.waterSource,
    required this.manual,
    required this.autoSoil,
    required this.scheduleEnabled,
    required this.strongRain,
    required this.phBlocked,
    required this.tank,
    required this.level,
    required this.pondTank,
    required this.pondLevel,
    required this.fill,
    required this.rain,
    required this.pond,
    required this.overflow,
    required this.overflowTarget,
    required this.remainingSec,
  });

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'on') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
    }
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory DeviceStateModel.fromJson(Map<String, dynamic> json) {
    return DeviceStateModel(
      id: (json['id'] ?? '').toString(),
      irrigationRunning: _asBool(json['ir']),
      source: (json['src'] ?? 'NONE').toString(),
      waterSource: (json['wsrc'] ?? 'NONE').toString(),

      manual: _asBool(json['man']),
      autoSoil: _asBool(json['asoil']),
      scheduleEnabled: _asBool(json['sch']),
      strongRain: _asBool(json['wx']),
      phBlocked: _asBool(json['phb']),

      tank: (json['tank'] ?? 'UNKNOWN').toString(),
      level: _asDouble(json['lvl']),

      pondTank: (json['ptank'] ?? 'UNKNOWN').toString(),
      pondLevel: _asDouble(json['plvl']),

      fill: _asBool(json['fill']),
      rain: _asBool(json['rain']),
      pond: _asBool(json['pond']),

      overflow: _asBool(json['ovf'], fallback: _asBool(json['fill'])),
      overflowTarget: (json['ovt'] ?? 'NONE').toString(),

      remainingSec: _asInt(json['rem']),
    );
  }
}