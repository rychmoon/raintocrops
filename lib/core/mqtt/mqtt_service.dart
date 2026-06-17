import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttMessageData {
  final String topic;
  final Map<String, dynamic> payload;

  MqttMessageData({
    required this.topic,
    required this.payload,
  });
}

class MqttService {
  MqttServerClient? _client;

  final StreamController<MqttMessageData> _messages =
  StreamController<MqttMessageData>.broadcast();

  Stream<MqttMessageData> get messages => _messages.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    required String clientId,
  }) async {
    try {
      debugPrint('MQTT connect() called');
      debugPrint('MQTT host: $host');
      debugPrint('MQTT port: $port');
      debugPrint('MQTT username: $username');
      debugPrint('MQTT password exists: ${password.isNotEmpty}');
      debugPrint('MQTT clientId: $clientId');

      final client = MqttServerClient(host, clientId);

      client.port = port;
      client.secure = true;
      client.keepAlivePeriod = 20;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;
      client.logging(on: true);
      client.securityContext = SecurityContext.defaultContext;

      client.onBadCertificate = (dynamic certificate) {
        debugPrint('MQTT onBadCertificate: $certificate');
        return true;
      };

      client.onConnected = () {
        debugPrint('MQTT connected');
      };

      client.onDisconnected = () {
        debugPrint('MQTT disconnected');
      };

      client.onSubscribed = (String topic) {
        debugPrint('MQTT subscribed: $topic');
      };

      client.pongCallback = () {
        debugPrint('MQTT ping response received');
      };

      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .withProtocolName('MQTT')
          .withProtocolVersion(4)
          .startClean();

      final result = await client.connect();

      debugPrint('MQTT connection result state: ${result?.state}');
      debugPrint('MQTT connection status: ${client.connectionStatus?.state}');
      debugPrint('MQTT return code: ${client.connectionStatus?.returnCode}');

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        debugPrint(
          'MQTT failed. Return code: ${client.connectionStatus?.returnCode}',
        );
        client.disconnect();
        return false;
      }

      _client = client;

      _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> events) {
        for (final event in events) {
          final publishMessage = event.payload as MqttPublishMessage;
          final payloadString = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message,
          );

          debugPrint('MQTT incoming topic: ${event.topic}');
          debugPrint('MQTT incoming payload: $payloadString');

          try {
            final decoded = jsonDecode(payloadString) as Map<String, dynamic>;
            _messages.add(
              MqttMessageData(
                topic: event.topic,
                payload: decoded,
              ),
            );
          } catch (e) {
            debugPrint('Invalid JSON from ${event.topic}: $payloadString');
          }
        }
      });

      return true;
    } catch (e, st) {
      debugPrint('MQTT connect error: $e');
      debugPrint('$st');
      _client?.disconnect();
      return false;
    }
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (!isConnected) {
      debugPrint('MQTT subscribe skipped, not connected: $topic');
      return;
    }
    _client!.subscribe(topic, qos);
  }

  void publish(
      String topic,
      Map<String, dynamic> payload, {
        MqttQos qos = MqttQos.atLeastOnce,
      }) {
    if (!isConnected) {
      debugPrint('MQTT publish skipped, not connected: $topic');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    _client!.publishMessage(topic, qos, builder.payload!);
  }

  void publishRaw(
      String topic,
      String payload, {
        MqttQos qos = MqttQos.atMostOnce,
      }) {
    if (!isConnected) {
      debugPrint('MQTT publishRaw skipped, not connected: $topic');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client!.publishMessage(topic, qos, builder.payload!);
  }

  void disconnect() {
    _client?.disconnect();
  }

  void dispose() {
    _client?.disconnect();
    _messages.close();
  }
}