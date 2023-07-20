import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mqtt_ui/mqtt/state/MQTTAppState.dart';
import 'package:mqtt_ui/mqtt/MQTTManager.dart';
import 'package:telephony/telephony.dart';
import 'dart:async';

class MQTTView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MQTTViewState();
  }
}

class _MQTTViewState extends State<MQTTView> {
  /* Initializing the TextEditingControllers to store host address, message, 
  topic and phone number.  */

  final TextEditingController hostTextController = TextEditingController();
  final TextEditingController messageTextController = TextEditingController();
  final TextEditingController topicTextController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Creating an instance of MQTTAppState and MQTTManager

  late MQTTAppState currentAppState;
  late MQTTManager manager;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    hostTextController
        .dispose(); //dispose textcontroller when it is no longer needed
    messageTextController
        .dispose(); // This will discard resources used by the object
    topicTextController.dispose();
    super.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /* Create an instance of the the Provider Class MQTTAppState
       and store it in variable appState, then assign it to 
       currentAppState
    */
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    currentAppState = appState;

    /* Returning the Scaffold widget with body buildColumn
    */
    return Scaffold(body: buildColumn());
  }

  Widget buildAppBar() {
    return AppBar(
      title: const Text('MQTT'),
      backgroundColor: Colors.greenAccent,
    );
  }

  /*This builds the column of the ui. Widgets in order are
    buildConnectionStateText 
    buildEditableColumn
    buildScrollableTextWith 
  */
  Widget buildColumn() {
    return Column(
      children: <Widget>[
        buildConnectionStateText(prepareStateMessageFrom(currentAppState
            .getAppConnectionState)), // Passing the connection state as a text to buildConnectionStateText
        buildEditableColumn(),
        buildScrollableTextWith(currentAppState
            .getHistoryText) //Passing the history text to buildScrollableTextWith
      ],
    );
  }

  /*This widget displays the connection state. Connected/connecting/Disconnecting.
  status gets connection state from currentAppState.getAppConnectionState
   green if connected, orange if disconnected
   */
  Widget buildConnectionStateText(String status) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
              color: (currentAppState.getAppConnectionState ==
                      MQTTAppConnectionState.connected)
                  ? Colors.green
                  : Colors.orange,
              child: Text(status, textAlign: TextAlign.center)),
        ),
      ],
    );
  }

  /*Returns the string value from the enum.
  */
  String prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        return 'Connected';
      case MQTTAppConnectionState.connecting:
        return 'Connecting';
      case MQTTAppConnectionState.disconnected:
        return 'Disconnected';
    }
  }

/*This widget builds the Host field, Topic Field, Publish Message field, 
Phone number field, send button and connect button
Address field and Topic field is built using _buildTextFieldWith() widget
Message Field and connect button are built using _buildPublishMessageRow()
*/
  Widget buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          buildTextFieldWith(hostTextController, 'Enter broker address',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          buildTextFieldWith(
              topicTextController,
              'Enter a topic to subscribe or listen',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          buildPhoneFieldWith(phoneController, 'Enter Phone Number',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          buildPublishMessageRow(),
          const SizedBox(height: 10),
          buildConnecteButtonFrom(currentAppState.getAppConnectionState)
        ],
      ),
    );
  }

  /*This widget builds the Host field and topic field.
  First it checks the condition for them to be enabled.
  If disconnected, both address field and topic field are enabled and message field disabled
  Once connected, address field and topic field are disabled, message field enabled
  It accepts (controller, field_label, state)
  */
  Widget buildTextFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if ((controller == messageTextController &&
            state == MQTTAppConnectionState.connected) ||
        (controller == phoneController &&
            state == MQTTAppConnectionState.connected)) {
      shouldEnable = true;
    } else if ((controller == hostTextController &&
            state == MQTTAppConnectionState.disconnected) ||
        (controller == topicTextController &&
            state == MQTTAppConnectionState.disconnected)) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  /*This widget builds the phone number field.If topic is 'sms', phone number 
    field is enabled.
  */
  Widget buildPhoneFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if (topicTextController.text.toLowerCase() == 'sms') {
      shouldEnable = true;
    } else {
      shouldEnable = false;
      phoneController.clear();
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  /*This widget builds the Message Field and the send button.
  */
  Widget buildPublishMessageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: buildTextFieldWith(messageTextController, 'Enter a message',
              currentAppState.getAppConnectionState), /*Builds message field*/
        ),
        buildSendButtonFrom(
            currentAppState.getAppConnectionState) /*Builds send button*/
      ],
    );
  }

  /*This widget builds the send button. On Pressing the send button, publishMessage
  function is executed. If topic is sms, sms sendSMS function is also executed.
  */
  Widget buildSendButtonFrom(MQTTAppConnectionState state) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      child: const Text('Send'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              publishMessage(messageTextController.text);
              if (topicTextController.text == 'sms') {
                sendSMS(phoneController.text, messageTextController.text);
              }
            }
          : null, //
    );
  }

  /*This function publishes the message
  */
  void publishMessage(String text) {
    String osPrefix = 'Flutter_iOS';
    if (Platform.isAndroid) {
      osPrefix = 'Flutter_Android';
    }
    final String message = osPrefix + ' says: ' + text;
    manager.publish(message);
  }

  /*This widget builds the connect and disconnect button.
    On pressing connect button, configureAndConnect function is executed.
  */
  Widget buildConnecteButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          // ignore: deprecated_member_use
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent),
            child: const Text('Connect'),
            onPressed: state == MQTTAppConnectionState.disconnected
                ? configureAndConnect /*OnPressed, the configureAndConnect button is executed*/
                : null, //
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // ignore: deprecated_member_use
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Disconnect'),
            onPressed: state == MQTTAppConnectionState.connected
                ? disconnect
                : null, //
          ),
        ),
      ],
    );
  }

  /*On Pressing the connect button, This function is executed. We create MQTTManager instance
  with all the details like hostname,topic,identifier and AppState.
  It first gets initialized and then connected
  */
  void configureAndConnect() {
    manager = MQTTManager(
        host: hostTextController.text,
        topic: topicTextController.text,
        identifier: "",
        currentState: currentAppState);
    manager
        .initializeMQTTClient(); /*This is where the subscribed messages are getting listened to.In the initializeMQTTClient function there is onConnected which listens for updates and runs in the backround*/
    manager.connect();
  }

  /*This is the ScrollableText widget which displays the history text
  */
  Widget buildScrollableTextWith(String text) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: 400,
        height: 200,
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
    );
  }

  void disconnect() {
    manager.disconnect();
  }

  /*This function sends the Sms
  */
  sendSMS(String number, String message) async {
    Telephony telephony =
        Telephony.instance; // Create an instance of the Telephony class
    telephony.sendSms(to: number, message: message);
    messageTextController.clear();
  }

  _getSMS() async {
    Telephony telephony =
        Telephony.instance;
    List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter:
            SmsFilter.where(SmsColumn.ADDRESS).equals(phoneController.text));

    for (var msg in messages) {
      print(msg.body);
    }
  }
}
