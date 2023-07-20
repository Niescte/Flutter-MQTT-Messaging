/*This class updates all the value changes on the ui screen.
The ui screen has an implementation of a widget and the supporting methods in this class notifies the widgets
of the change in value to be executed and displayed
*/

import 'package:flutter/cupertino.dart';

enum MQTTAppConnectionState { connected, disconnected, connecting }

class MQTTAppState with ChangeNotifier {
  /*Creating the change notifier class
  setting the enum value to disconnected
  */
  MQTTAppConnectionState _appConnectionState =
      MQTTAppConnectionState.disconnected;

  String _receivedText = '';
  String _historyText = '';

  /*This method _setRecieved takes in a text String and appends it to a variable
  with a line feeder and then this appended text to the history text and then we
  are notifying all the listeners.

  */
  void setReceivedText(String text) {
    _receivedText = text;
    _historyText = _historyText + '\n' + _receivedText;
    //Notifying all the listeners that implement this value change
    notifyListeners();
  }

  /*Sets the app connection state and notifies listeners
  */
  void setAppConnectionState(MQTTAppConnectionState state) {
    _appConnectionState = state;
    notifyListeners();
  }

  /*getters*/
  String get getReceivedText => _receivedText;
  String get getHistoryText => _historyText;
  MQTTAppConnectionState get getAppConnectionState => _appConnectionState;
}
