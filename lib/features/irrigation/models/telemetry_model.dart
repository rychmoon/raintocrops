class TelemetryModel {
  final String id;

  // Tank
  final double level; // lvl
  final double volume; // vol
  final String tankStatus; // ts
  final double distance; // dist

  // Pond
  final double pondLevel; // plvl
  final double pondVolume; // pvol
  final String pondStatus; // pts
  final double pondDistance; // pdist

  // Flow
  final double flow; // fl
  final double collected; // cl

  // pH
  final double ph; // ph
  final String phCondition; // pcn
  final bool phBottle; // pb

  // Soil
  final List<int> soilRaw; // sr
  final List<int> soilPercent; // sp
  final List<int> plotPercent; // pp
  final String soilStatus; // ss

  // Weather
  final double rain6h; // r6
  final double rain3h; // r3
  final double rain12h; // r12
  final double pop3; // pop3
  final double pop6; // pop6
  final double pop12; // pop12
  final double reta; // next rain ETA
  final bool wxok; // weather data valid
  final bool wxst; // weather stale

  final String wxsd; // schedule weather decision
  final String wxsr; // schedule weather reason
  final double wxss; // schedule shortened duration

  final String wxad; // auto-soil weather decision
  final String wxar; // auto-soil weather reason
  final double wxas; // auto-soil shortened duration

  final String iwx; // irrigation weather action applied
  final String iwxr; // irrigation weather reason

  // Irrigation duration from ESP
  final int requestedIrrigationSec; // idur_req
  final int appliedIrrigationSec; // idur_app

  // Runtime
  final bool irrigationRunning; // ir
  final String source; // src
  final String waterSource; // wsrc

  // Overflow
  final bool filling; // fill
  final bool overflow; // ovf
  final String overflowTarget; // ovt

  // Relay states
  final List<bool> relays; // r

  const TelemetryModel({
    required this.id,
    required this.level,
    required this.volume,
    required this.tankStatus,
    required this.distance,
    required this.pondLevel,
    required this.pondVolume,
    required this.pondStatus,
    required this.pondDistance,
    required this.flow,
    required this.collected,
    required this.ph,
    required this.phCondition,
    required this.phBottle,
    required this.soilRaw,
    required this.soilPercent,
    required this.plotPercent,
    required this.soilStatus,
    required this.rain6h,
    required this.rain3h,
    required this.rain12h,
    required this.pop3,
    required this.pop6,
    required this.pop12,
    required this.reta,
    required this.wxok,
    required this.wxst,
    required this.wxsd,
    required this.wxsr,
    required this.wxss,
    required this.wxad,
    required this.wxar,
    required this.wxas,
    required this.iwx,
    required this.iwxr,
    required this.requestedIrrigationSec,
    required this.appliedIrrigationSec,
    required this.irrigationRunning,
    required this.source,
    required this.waterSource,
    required this.filling,
    required this.overflow,
    required this.overflowTarget,
    required this.relays,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      id: json['id'] ?? '',

      level: (json['lvl'] as num?)?.toDouble() ?? 0.0,
      volume: (json['vol'] as num?)?.toDouble() ?? 0.0,
      tankStatus: json['ts'] ?? 'UNKNOWN',
      distance: (json['dist'] as num?)?.toDouble() ?? 0.0,

      pondLevel: (json['plvl'] as num?)?.toDouble() ?? 0.0,
      pondVolume: (json['pvol'] as num?)?.toDouble() ?? 0.0,
      pondStatus: json['pts'] ?? 'UNKNOWN',
      pondDistance: (json['pdist'] as num?)?.toDouble() ?? 0.0,

      flow: (json['fl'] as num?)?.toDouble() ?? 0.0,
      collected: (json['cl'] as num?)?.toDouble() ?? 0.0,

      ph: (json['ph'] as num?)?.toDouble() ?? 0.0,
      phCondition: json['pcn'] ?? 'UNKNOWN',
      phBottle: json['pb'] ?? false,

      soilRaw: List<int>.from(json['sr'] ?? const []),
      soilPercent: List<int>.from(json['sp'] ?? const []),
      plotPercent: List<int>.from(json['pp'] ?? const []),
      soilStatus: json['ss'] ?? 'UNKNOWN',

      rain6h: (json['r6'] as num?)?.toDouble() ?? 0.0,
      rain3h: (json['r3'] as num?)?.toDouble() ?? 0.0,
      rain12h: (json['r12'] as num?)?.toDouble() ?? 0.0,
      pop3: (json['pop3'] as num?)?.toDouble() ?? 0.0,
      pop6: (json['pop6'] as num?)?.toDouble() ?? 0.0,
      pop12: (json['pop12'] as num?)?.toDouble() ?? 0.0,
      reta: (json['reta'] as num?)?.toDouble() ?? 0.0,
      wxok: json['wxok'] ?? false,
      wxst: json['wxst'] ?? false,

      wxsd: json['wxsd'] ?? 'UNKNOWN',
      wxsr: json['wxsr'] ?? 'UNKNOWN',
      wxss: (json['wxss'] as num?)?.toDouble() ?? 0.0,

      wxad: json['wxad'] ?? 'UNKNOWN',
      wxar: json['wxar'] ?? 'UNKNOWN',
      wxas: (json['wxas'] as num?)?.toDouble() ?? 0.0,

      iwx: json['iwx'] ?? 'UNKNOWN',
      iwxr: json['iwxr'] ?? 'UNKNOWN',

      requestedIrrigationSec: (json['idur_req'] as num?)?.toInt() ?? 0,
      appliedIrrigationSec: (json['idur_app'] as num?)?.toInt() ?? 0,

      irrigationRunning: json['ir'] ?? false,
      source: json['src'] ?? 'NONE',
      waterSource: json['wsrc'] ?? 'NONE',

      filling: json['fill'] ?? false,
      overflow: json['ovf'] ?? (json['fill'] ?? false),
      overflowTarget: json['ovt'] ?? 'NONE',

      relays: List<bool>.from(
        json['r'] ?? const [false, false, false, false, false, false, false],
      ),
    );
  }
}