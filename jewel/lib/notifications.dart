import 'package:awesome_notifications/awesome_notifications.dart';

class NotifcationController{
  static ReceivedAction? initialAction;
  static Future<void> initializeLocalNotifcations() async{
    await AwesomeNotifications().initialize(null, [
      NotificationChannel()
    ]);
  }




}