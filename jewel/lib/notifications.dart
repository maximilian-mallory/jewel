import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jewel/main.dart';

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
ReceivedAction receivedAction
) async{
  if(receivedAction.actionType== ActionType.SilentAction || receivedAction.actionType==ActionType.SilentBackgroundAction){
    print('Message sent via notification input: "$ReceivedAction.buttonKeyInput}"');
    await executeLongTaskInBackground();
  }else {
      // this process is only necessary when you need to redirect the user
      // to a new page or use a valid context, since parallel isolates do not
      // have valid context, so you need redirect the execution to main isolate
      if (receivePort == null) {
        print(
            'onActionReceivedMethod was called inside a parallel dart isolate.');
        SendPort? sendPort =
            IsolateNameServer.lookupPortByName('notification_action_port');

        if (sendPort != null) {
          print('Redirecting the execution to main isolate process.');
          sendPort.send(receivedAction);
          return;
        }
      }

      return onActionReceivedImplementationMethod(receivedAction);
    }
}

static Future<void> onActionReceivedImplementationMethod(
  ReceivedAction receivedAction) async{
    MyApp.navigatorKey.currentState?.pushNamedAndRemovedUntil(
      '/notification-page', (route)=> (route.settings.name != '/notification-page')|| route.isFirst,
     arguments: receivedAction); 
    
  }



}