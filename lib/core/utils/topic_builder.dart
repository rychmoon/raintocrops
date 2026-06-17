class TopicBuilder {
  static String base(String deviceId) => 'raintocrops/device/$deviceId';

  static String meta(String deviceId) => '${base(deviceId)}/meta';
  static String telemetry(String deviceId) => '${base(deviceId)}/telemetry';
  static String state(String deviceId) => '${base(deviceId)}/state';
  static String notify(String deviceId) => '${base(deviceId)}/notify';
  static String scheduleState(String deviceId) =>
      '${base(deviceId)}/schedule/state';

  static String command(String deviceId) => '${base(deviceId)}/cmd';
  static String scheduleSet(String deviceId) =>
      '${base(deviceId)}/schedule/set';
  static String stateGet(String deviceId) => '${base(deviceId)}/state/get';
}