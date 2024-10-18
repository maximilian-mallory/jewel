import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationController{
  static ReceivedAction? initialAction;
  static Future<void> initializeLocalNotifcations() async{
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'event notifications',
        channelName: 'events',
        channelDescription: 'Event Notifications to test',
        playSound: true,
        onlyAlertOnce: true,
        groupAlertBehavior: GroupAlertBehavior.Children,
        importance: NotificationImportance.High,
        defaultPrivacy: NotificationPrivacy.Private,
        defaultColor: Colors.cyan,
        ledColor: Colors.deepOrange
      )
    ],
    debug: true);

  initialAction = await AwesomeNotifications().getInitialNotificationAction(removeFromActionEvents: false);
  }

  static ReceivePort? receivePort;
  static Future<void> initializeIsolateReceivePort() async {
    receivePort = ReceivePort('Notification action port in main isolate')
      ..listen(
          (silentData) => onActionReceivedImplementationMethod(silentData));

    // This initialization only happens on main isolate
    IsolateNameServer.registerPortWithName(
        receivePort!.sendPort, 'notification_action_port');
  }

static Future<void> startListeningNotificationEvents() async {
  AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceivedMethod);
}

@pragma('vm:entry-point')
static Future<void> onActionReceivedMethod(
ReceivedAction ReceivedAction
) async{
  if(ReceivedAction.actionType== ActionType.SilentAction || ReceivedAction.actionType==ActionType.SilentBackgroundAction){
    
  }


}



}