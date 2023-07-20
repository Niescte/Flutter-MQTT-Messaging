import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_ui/mqtt/state/MQTTAppState.dart';

class MQTTManager {
  /*Creating the instance variables
  */
  final MQTTAppState currentState;
  MqttServerClient? client;
  final String identifier;
  final String host;
  final String topic;

  /*Constructor to accept the host,topic,identifier and currentState
 */
  MQTTManager(
      {required this.host,
      required this.topic,
      required this.identifier,
      required this.currentState});

  void initializeMQTTClient() {
    client = MqttServerClient(host, identifier);
    client!.port = 1883;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = onDisconnected;
    client!.secure = false;
    client!.logging(on: false);

    client!.onConnected = onConnected;
    client!.onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non-persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    client!.connectionMessage = connMess;
  }

  /*This function connects to the mqtt server. IF it's dosent connect,
  catches the exception and disconnects
  */
  void connect() async {
    assert(client != null);
    try {
      print('EXAMPLE::Mosquitto start client connecting....');
      currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      await client!.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
    }
  }

  /*This function disconnects from the mqtt server*/
  void disconnect() {
    print('Disconnected');
    client!.disconnect();
  }

  /*This function publishes the message to a specific topic*/
  void publish(String message) {
    /*a new instance of the MqttClientPayloadBuilder class is created and assigned to the variable builder.
    MqttClientPayloadBuilder class is used in MQTT protocol implementations to build the payload data for publishing a message.*/
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    /*appends a string message to the payload builder*/
    builder.addString(message);
    /*Publishes the message to the given topic*/
    client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /*Callback when client is diconnected*/
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client!.connectionStatus!.returnCode ==
        MqttConnectReturnCode.noneSpecified) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
    currentState.setAppConnectionState(MQTTAppConnectionState.disconnected);
  }

  /*Here the mqttmanager listens for updates in the subscribed topic*/
  void onConnected() {
    /*sets enum value of connection state as connected*/
    currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    print('EXAMPLE::Mosquitto client connected....');
    /*Subscribes to the topic*/
    client!.subscribe(topic, MqttQos.atLeastOnce);
    /*This line sets up a listener on the updates stream of the MQTT client. The updates stream provides a stream of incoming messages.
    Whenever a new message is received, the listener function is invoked.*/
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;

      // final MqttPublishMessage recMess = c![0].payload;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
      currentState.setReceivedText(
          pt); //Everytime it recieves a message, it is added to recievedText
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });
    print(
        'EXAMPLE::OnConnected client callback - Client connection was sucessful');
  }
}
