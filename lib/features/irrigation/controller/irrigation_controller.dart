import 'dart:async';
import 'package:flutter/material.dart';

import '/core/env/app_env.dart';
import '/core/mqtt/mqtt_service.dart';
import '/core/utils/topic_builder.dart';
import '/core/utils/tank_sustain_predictor.dart';
import '/core/notification/controller/notification_controller.dart';
import '/features/roles/service/device_service.dart';
import '/features/irrigation/models/device_state_model.dart';
import '/features/irrigation/models/notify_model.dart';
import '/features/irrigation/models/schedule_model.dart';
import '/features/irrigation/models/telemetry_model.dart';
import '/features/irrigation/services/tank_insight_cache.dart';
import '/features/collected_rain_statistics/rain_history_service.dart';

class IrrigationController extends ChangeNotifier {
  IrrigationController({
    required MqttService mqttService,
    DeviceService? deviceService,
    RainHistoryService? rainHistoryService,
  })  : _mqttService = mqttService,
        _deviceService = deviceService ?? DeviceService(),
        _rainHistoryService = rainHistoryService ?? RainHistoryService();

  final MqttService _mqttService;
  final DeviceService _deviceService;
  final RainHistoryService _rainHistoryService;

  NotificationController? _notificationController;
  StreamSubscription? _messageSub;

  String? _deviceId;
  bool _canControl = false;
  bool _registrySynced = false;
  bool _isDisposed = false;

  bool isConnected = false;
  bool isLoading = false;

  TelemetryModel? telemetry;
  DeviceStateModel? state;
  NotifyModel? notifyData;
  ScheduleStateModel scheduleState = ScheduleStateModel.empty();

  CachedTankInsight? cachedTankInsight;

  bool? _mainPumpOverride;
  bool? _valveOverride;
  bool? _valve2ToPondOverride;
  bool? _valve3ToReserveOverride;
  bool? _irrigationOverride;
  bool? _pondOverride;
  bool? _dosingOverride;

  Timer? _manualIrrigationTimer;
  static const int _manualIrrigationMaxSeconds = 60;
  int _manualIrrigationRemainingSeconds = 0;

  bool _didShowInitialConnectionNotification = false;
  bool _didGenerateInitialStateNotifications = false;
  bool _didGenerateInitialTelemetryNotifications = false;

  DateTime? _lastRainHistorySavedAt;
  double? _lastSavedCollectedValue;
  String? _lastSavedDateKey;

  static const Duration _rainHistoryMinSaveGap = Duration(minutes: 1);
  static const double _rainHistoryMinCollectedDelta = 0.05;

  String? get deviceId => _deviceId;
  bool get hasBoundDevice => _deviceId != null;
  bool get canControl => _canControl;

  List<ScheduleItemModel> get schedules => scheduleState.items;

  TankSustainPredictionResult? get tankSustainPrediction {
    final currentTelemetry = telemetry;
    if (currentTelemetry == null) return null;

    final scheduleInputs = schedules.map((schedule) {
      return TankScheduleUsageInput(
        durationSec: schedule.duration,
        active: schedule.enabled,
        days: schedule.days,
      );
    }).toList();

    return TankSustainPredictor.predict(
      telemetry: currentTelemetry,
      schedules: scheduleInputs,
      litersPer60Sec: 3.00,
      reserveLiters: 20.0,
      includeAutoSoilEstimate: true,
      autoSoilDurationSec: 60,
      estimatedAutoSoilRunsPerDayWhenDry: 1.0,
    );
  }

  dynamic get tankInsightForDisplay {
    return tankSustainPrediction ?? cachedTankInsight;
  }

  bool get isUsingCachedTankInsight {
    return tankSustainPrediction == null && cachedTankInsight != null;
  }

  void setNotificationController(NotificationController controller) {
    _notificationController = controller;
  }

  void setPermission(bool value) {
    if (_canControl == value) return;
    _canControl = value;
    notifyListeners();
  }

  Future<void> _loadCachedTankInsight() async {
    final deviceId = _deviceId;
    if (deviceId == null) return;

    cachedTankInsight = await TankInsightCacheService.loadLatest(
      deviceId: deviceId,
    );

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _saveTankInsightCacheIfReady() {
    final deviceId = _deviceId;
    if (deviceId == null) return;

    final prediction = tankSustainPrediction;
    if (prediction == null) return;

    cachedTankInsight = CachedTankInsight.fromPrediction(prediction);

    unawaited(
      TankInsightCacheService.saveFromPrediction(
        deviceId: deviceId,
        prediction: prediction,
      ),
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool _shouldSaveRainHistory(TelemetryModel telemetry) {
    final now = DateTime.now();
    final currentDateKey = _dateKey(now);

    if (_lastSavedDateKey != currentDateKey) return true;
    if (_lastRainHistorySavedAt == null) return true;

    final timePassed = now.difference(_lastRainHistorySavedAt!);
    if (timePassed >= _rainHistoryMinSaveGap) return true;

    if (_lastSavedCollectedValue == null) return true;

    final collectedDelta =
    (telemetry.collected - _lastSavedCollectedValue!).abs();

    if (collectedDelta >= _rainHistoryMinCollectedDelta) return true;

    return false;
  }

  void _saveRainHistoryIfNeeded(TelemetryModel telemetry) {
    if (_deviceId == null) return;
    if (!_shouldSaveRainHistory(telemetry)) return;

    final now = DateTime.now();

    _lastRainHistorySavedAt = now;
    _lastSavedCollectedValue = telemetry.collected;
    _lastSavedDateKey = _dateKey(now);

    unawaited(
      _rainHistoryService.saveDailyTelemetry(
        deviceId: _deviceId!,
        telemetry: telemetry,
        now: now,
      ),
    );
  }

  bool _isRainExpectedFromTelemetry(TelemetryModel t) {
    final decision = t.wxsd.toLowerCase();
    final reason = t.wxsr.toLowerCase();
    final action = t.iwx.toLowerCase();
    final actionReason = t.iwxr.toLowerCase();

    final decisionSignalsRain =
        decision.contains('skip') || decision.contains('shorten');

    final reasonSignalsRain =
        reason.contains('rain') || reason.contains('pop');

    final actionSignalsRain =
        action.contains('skip') || action.contains('shorten');

    final actionReasonSignalsRain =
        actionReason.contains('rain') || actionReason.contains('pop');

    final highPop = t.pop3 >= 60 || t.pop6 >= 60 || t.pop12 >= 60;

    return decisionSignalsRain ||
        reasonSignalsRain ||
        actionSignalsRain ||
        actionReasonSignalsRain ||
        highPop;
  }

  Future<void> bindDevice(String deviceId) async {
    if (_deviceId == deviceId && isConnected) return;

    await disconnect();

    _deviceId = deviceId;
    _registrySynced = false;
    _didShowInitialConnectionNotification = false;
    _didGenerateInitialStateNotifications = false;
    _didGenerateInitialTelemetryNotifications = false;

    _lastRainHistorySavedAt = null;
    _lastSavedCollectedValue = null;
    _lastSavedDateKey = null;

    await _loadCachedTankInsight();

    await connect();
  }

  Future<void> connect() async {
    if (_deviceId == null) return;

    isLoading = true;
    notifyListeners();

    isConnected = await _mqttService.connect(
      host: AppEnv.mqttHost,
      port: AppEnv.mqttPort,
      username: AppEnv.mqttUser,
      password: AppEnv.mqttPass,
      clientId: 'flutter_${_deviceId}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (isConnected) {
      _mqttService.subscribe(TopicBuilder.meta(_deviceId!));
      _mqttService.subscribe(TopicBuilder.telemetry(_deviceId!));
      _mqttService.subscribe(TopicBuilder.state(_deviceId!));
      _mqttService.subscribe(TopicBuilder.notify(_deviceId!));
      _mqttService.subscribe(TopicBuilder.scheduleState(_deviceId!));

      if (!_didShowInitialConnectionNotification) {
        _didShowInitialConnectionNotification = true;
        _notificationController?.addSystemNotification(
          deviceId: _deviceId!,
          code: 'device_connected_initial',
          title: 'Device connected',
          message: 'You are now connected to this device.',
          level: 'info',
        );
      }

      await _messageSub?.cancel();

      _messageSub = _mqttService.messages.listen((message) async {
        if (_deviceId == null || _isDisposed) return;

        try {
          if (message.topic == TopicBuilder.meta(_deviceId!)) {
            if (!_registrySynced && message.payload['pc'] != null) {
              _registrySynced = true;
              unawaited(_deviceService.syncPairingMeta(message.payload));
            }
          } else if (message.topic == TopicBuilder.telemetry(_deviceId!)) {
            telemetry = TelemetryModel.fromJson(message.payload);

            _saveRainHistoryIfNeeded(telemetry!);
            _saveTankInsightCacheIfReady();

            _mainPumpOverride = null;
            _valveOverride = null;
            _valve2ToPondOverride = null;
            _valve3ToReserveOverride = null;
            _pondOverride = null;
            _dosingOverride = null;

            if (!_isManualIrrigationCountingDown) {
              _irrigationOverride = null;
            }

            _generateInitialTelemetryNotifications();
          } else if (message.topic == TopicBuilder.state(_deviceId!)) {
            state = DeviceStateModel.fromJson(message.payload);
            _generateInitialStateNotifications();
          } else if (message.topic == TopicBuilder.notify(_deviceId!)) {
            notifyData = NotifyModel.fromJson(message.payload);
            _notificationController?.handleIncomingPayload(message.payload);
          } else if (message.topic == TopicBuilder.scheduleState(_deviceId!)) {
            scheduleState = ScheduleStateModel.fromJson(message.payload);
            _saveTankInsightCacheIfReady();
          }

          if (!_isDisposed) notifyListeners();
        } catch (_) {
          // Ignore malformed payload in stream.
        }
      });

      requestState();
    }

    isLoading = false;
    notifyListeners();
  }

  void _generateInitialStateNotifications() {
    if (_deviceId == null ||
        state == null ||
        _didGenerateInitialStateNotifications) {
      return;
    }

    _didGenerateInitialStateNotifications = true;

    _notificationController?.addSystemNotification(
      deviceId: _deviceId!,
      code: 'device_status_loaded',
      title: 'Device status loaded',
      message: 'The latest device status is now available.',
      level: 'info',
    );

    if (state!.irrigationRunning) {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_irrigation_running',
        title: 'Irrigation started',
        message: 'The watering process is already running on this device.',
        level: 'info',
      );
    }

    if (state!.fill) {
      final isOverflowToPond =
          state!.overflowTarget.toUpperCase() == 'POND' || state!.pond;

      final isOverflowToReserve =
          state!.overflowTarget.toUpperCase() == 'RESERVE';

      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_overflow_running',
        title: 'Overflow routing active',
        message: isOverflowToPond
            ? 'Excess water is currently routed to pond.'
            : isOverflowToReserve
            ? 'Excess water is currently routed to reserve container.'
            : 'Overflow routing is currently active.',
        level: 'info',
      );
    }

    if (state!.tank.toLowerCase() == 'low') {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_tank_low',
        title: 'Water level is low',
        message: 'The tank water level is currently low.',
        level: 'warning',
      );
    } else if (state!.tank.toLowerCase() == 'unknown') {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_tank_unknown',
        title: 'Tank level unavailable',
        message: 'The app cannot read the tank level right now.',
        level: 'warning',
      );
    }

    if (state!.phBlocked) {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_ph_blocked',
        title: 'Irrigation blocked',
        message: 'Watering is blocked because the pH is not safe.',
        level: 'warning',
      );
    }

    if (state!.strongRain) {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_strong_rain',
        title: 'Rain is expected',
        message: 'Rain is expected soon, so some watering may be skipped.',
        level: 'info',
      );
    }

    if (state!.scheduleEnabled) {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_schedule_enabled',
        title: 'Schedule is active',
        message: 'This device currently has an active watering schedule.',
        level: 'info',
      );
    }
  }

  void _generateInitialTelemetryNotifications() {
    if (_deviceId == null ||
        telemetry == null ||
        _didGenerateInitialTelemetryNotifications) {
      return;
    }

    _didGenerateInitialTelemetryNotifications = true;

    if (!telemetry!.phBottle) {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_ph_bottle_empty',
        title: 'pH bottle is empty',
        message: 'The pH bottle is empty. Please refill it.',
        level: 'warning',
      );
    }

    if (telemetry!.soilStatus.toLowerCase() == 'dry') {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_soil_dry',
        title: 'Soil is dry',
        message: 'The soil is currently dry.',
        level: 'info',
      );
    }

    if (_isRainExpectedFromTelemetry(telemetry!)) {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_weather_rain',
        title: 'Rain is expected',
        message: 'Rain is expected soon based on the latest weather check.',
        level: 'info',
      );
    }

    if (telemetry!.tankStatus.toLowerCase() == 'low') {
      _notificationController?.addSystemNotification(
        deviceId: _deviceId!,
        code: 'initial_telemetry_tank_low',
        title: 'Water level is low',
        message: 'The tank water level is low based on the latest reading.',
        level: 'warning',
      );
    }
  }

  Future<void> disconnect() async {
    _manualIrrigationTimer?.cancel();
    _manualIrrigationRemainingSeconds = 0;

    await _messageSub?.cancel();
    _messageSub = null;

    isConnected = false;
    _deviceId = null;
    _registrySynced = false;

    _didShowInitialConnectionNotification = false;
    _didGenerateInitialStateNotifications = false;
    _didGenerateInitialTelemetryNotifications = false;

    _lastRainHistorySavedAt = null;
    _lastSavedCollectedValue = null;
    _lastSavedDateKey = null;

    telemetry = null;
    state = null;
    notifyData = null;
    scheduleState = ScheduleStateModel.empty();
    cachedTankInsight = null;

    _mainPumpOverride = null;
    _valveOverride = null;
    _valve2ToPondOverride = null;
    _valve3ToReserveOverride = null;
    _irrigationOverride = null;
    _pondOverride = null;
    _dosingOverride = null;

    _mqttService.disconnect();
    notifyListeners();
  }

  void requestState() {
    if (_deviceId == null) return;
    _mqttService.publishRaw(TopicBuilder.stateGet(_deviceId!), '{}');
  }

  bool _guardControl() {
    return _canControl && _deviceId != null && isConnected;
  }

  // ─────────────────────────────────────────────
  // WIFI UPDATE
  // ─────────────────────────────────────────────

  /// Sends new WiFi credentials to the ESP32 over MQTT.
  ///
  /// The ESP32 will save the credentials to Preferences,
  /// overwriting any previously saved ones, then reconnect
  /// immediately using the new SSID and password.
  ///
  /// To revert the ESP32 back to its hardcoded default
  /// credentials, pass empty strings for both [ssid] and
  /// [password].
  ///
  /// Example:
  /// ```dart
  /// controller.updateWiFiCredentials(
  ///   ssid: 'MyHomeNetwork',
  ///   password: 'MyPassword123',
  /// );
  /// ```
  void updateWiFiCredentials({
    required String ssid,
    required String password,
  }) {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.command(_deviceId!),
      {
        'type': 'wifi_update',
        'ssid': ssid.trim(),
        'password': password.trim(),
      },
    );
  }

  // ─────────────────────────────────────────────
  // MANUAL IRRIGATION
  // ─────────────────────────────────────────────

  void startManualIrrigation({int duration = _manualIrrigationMaxSeconds}) {
    if (!_guardControl()) return;

    final deviceId = _deviceId;
    if (deviceId == null) return;

    _manualIrrigationTimer?.cancel();

    _manualIrrigationRemainingSeconds = duration;
    _irrigationOverride = true;
    notifyListeners();

    _mqttService.publish(
      TopicBuilder.command(deviceId),
      {
        'type': 'manual_irrigation',
        'on': true,
        'duration': duration,
      },
    );

    _manualIrrigationTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        if (_manualIrrigationRemainingSeconds <= 1) {
          timer.cancel();
          _manualIrrigationRemainingSeconds = 0;
          _irrigationOverride = false;
          notifyListeners();

          if (_deviceId != null && isConnected) {
            _mqttService.publish(
              TopicBuilder.command(_deviceId!),
              {
                'type': 'manual_irrigation',
                'on': false,
              },
            );
          }

          return;
        }

        _manualIrrigationRemainingSeconds--;
        notifyListeners();
      },
    );
  }

  void stopManualIrrigation() {
    if (!_guardControl()) return;

    _manualIrrigationTimer?.cancel();
    _manualIrrigationRemainingSeconds = 0;
    _irrigationOverride = false;
    notifyListeners();

    _mqttService.publish(
      TopicBuilder.command(_deviceId!),
      {
        'type': 'manual_irrigation',
        'on': false,
      },
    );
  }

  bool get _isManualIrrigationCountingDown {
    return _manualIrrigationRemainingSeconds > 0;
  }

  int get manualIrrigationRemainingSeconds {
    return _manualIrrigationRemainingSeconds;
  }

  bool get isManualIrrigationActive {
    return _isManualIrrigationCountingDown;
  }

  // ─────────────────────────────────────────────
  // FILL / OVERFLOW
  // ─────────────────────────────────────────────

  void startFill({String? target}) {
    if (!_guardControl()) return;

    final payload = <String, dynamic>{
      'type': 'manual_fill',
      'on': true,
    };

    if (target == 'pond' || target == 'reserve') {
      payload['target'] = target;
    }

    _mqttService.publish(TopicBuilder.command(_deviceId!), payload);
  }

  void stopFill() {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.command(_deviceId!),
      {
        'type': 'manual_fill',
        'on': false,
      },
    );
  }

  // ─────────────────────────────────────────────
  // AUTO SOIL
  // ─────────────────────────────────────────────

  void setAutoSoil(bool enabled) {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.command(_deviceId!),
      {
        'type': 'auto_soil',
        'enabled': enabled,
      },
    );
  }

  // ─────────────────────────────────────────────
  // RELAY CONTROL
  // ─────────────────────────────────────────────

  void setRelay({
    required String target,
    required bool on,
  }) {
    if (!_guardControl()) return;

    switch (target) {
      case 'main_pump':
        _mainPumpOverride = on;
        break;
      case 'valve':
      case 'valve1':
        _valveOverride = on;
        break;
      case 'valve2':
      case 'to_pond':
        _valve2ToPondOverride = on;
        break;
      case 'valve3':
      case 'to_reserve':
        _valve3ToReserveOverride = on;
        break;
      case 'pressure_pump':
        _irrigationOverride = on;
        break;
      case 'pond_pump':
        _pondOverride = on;
        break;
      case 'dosing':
        _dosingOverride = on;
        break;
    }

    notifyListeners();

    _mqttService.publish(
      TopicBuilder.command(_deviceId!),
      {
        'type': 'relay',
        'target': target,
        'on': on,
      },
    );
  }

  void setMainPump(bool on) => setRelay(target: 'main_pump', on: on);
  void setValve(bool on) => setRelay(target: 'valve', on: on);
  void setValve2ToPond(bool on) => setRelay(target: 'valve2', on: on);
  void setValve3ToReserve(bool on) => setRelay(target: 'valve3', on: on);
  void setPondPump(bool on) => setRelay(target: 'pond_pump', on: on);
  void setIrrigationPump(bool on) => setRelay(target: 'pressure_pump', on: on);
  void setDosingPump(bool on) => setRelay(target: 'dosing', on: on);

  // ─────────────────────────────────────────────
  // RELAY STATE GETTERS
  // ─────────────────────────────────────────────

  bool get mainPumpOn {
    return _mainPumpOverride ??
        (telemetry != null && telemetry!.relays.isNotEmpty
            ? telemetry!.relays[0]
            : false);
  }

  bool get valveOn {
    return _valveOverride ??
        (telemetry != null && telemetry!.relays.length > 1
            ? telemetry!.relays[1]
            : false);
  }

  bool get valve2ToPondOn {
    return _valve2ToPondOverride ??
        (telemetry != null && telemetry!.relays.length > 2
            ? telemetry!.relays[2]
            : false);
  }

  bool get valve3ToReserveOn {
    return _valve3ToReserveOverride ??
        (telemetry != null && telemetry!.relays.length > 3
            ? telemetry!.relays[3]
            : false);
  }

  bool get pondPumpOn {
    return _pondOverride ??
        (telemetry != null && telemetry!.relays.length > 4
            ? telemetry!.relays[4]
            : false);
  }

  bool get irrigationPumpOn {
    return _irrigationOverride ??
        (_isManualIrrigationCountingDown
            ? true
            : (telemetry != null && telemetry!.relays.length > 5
            ? telemetry!.relays[5]
            : false));
  }

  bool get dosingPumpOn {
    return _dosingOverride ??
        (telemetry != null && telemetry!.relays.length > 6
            ? telemetry!.relays[6]
            : false);
  }

  // ─────────────────────────────────────────────
  // STOP ALL
  // ─────────────────────────────────────────────

  void stopAll() {
    if (!_guardControl()) return;

    _manualIrrigationTimer?.cancel();
    _manualIrrigationRemainingSeconds = 0;

    _mainPumpOverride = false;
    _valveOverride = false;
    _valve2ToPondOverride = false;
    _valve3ToReserveOverride = false;
    _irrigationOverride = false;
    _pondOverride = false;
    _dosingOverride = false;

    notifyListeners();

    _mqttService.publish(
      TopicBuilder.command(_deviceId!),
      {
        'type': 'stop_all',
      },
    );
  }

  // ─────────────────────────────────────────────
  // SCHEDULES
  // ─────────────────────────────────────────────

  void addSchedule({
    required String time,
    required int duration,
    required List<int> days,
    bool active = true,
  }) {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.scheduleSet(_deviceId!),
      {
        'action': 'add',
        'time': time,
        'duration': duration,
        'days': days,
        'active': active,
      },
    );
  }

  void editSchedule({
    required int id,
    required String time,
    required int duration,
    required List<int> days,
    bool active = true,
  }) {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.scheduleSet(_deviceId!),
      {
        'action': 'edit',
        'id': id,
        'time': time,
        'duration': duration,
        'days': days,
        'active': active,
      },
    );
  }

  void toggleSchedule({
    required int id,
    required bool active,
  }) {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.scheduleSet(_deviceId!),
      {
        'action': 'toggle',
        'id': id,
        'active': active,
      },
    );
  }

  void deleteSchedule({
    required int id,
  }) {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.scheduleSet(_deviceId!),
      {
        'action': 'delete',
        'id': id,
      },
    );
  }

  void clearAllSchedules() {
    if (!_guardControl()) return;

    _mqttService.publish(
      TopicBuilder.scheduleSet(_deviceId!),
      {
        'action': 'clear_all',
      },
    );
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  @override
  void dispose() {
    _isDisposed = true;
    _manualIrrigationTimer?.cancel();
    _messageSub?.cancel();
    _mqttService.dispose();
    super.dispose();
  }
}