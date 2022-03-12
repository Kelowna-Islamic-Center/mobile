import 'package:firebase_messaging/firebase_messaging.dart';

class AnnouncementsCMWorker {

  // Announcements cloud message receiver
  Future<void> _messageHandler(RemoteMessage message) async {
    print('background message ${message.notification!.body}');
  }

  void init() {
    FirebaseMessaging.onBackgroundMessage(_messageHandler);
    // TODO: If LocalStorage value is null then subscribe to topic
    FirebaseMessaging.instance
        .requestPermission(sound: true, badge: true, alert: true);
  }

  void subscribe() {
    FirebaseMessaging.instance.subscribeToTopic("announcements");
  }

  void unsubscribe() {
    FirebaseMessaging.instance.unsubscribeFromTopic("announcements");
  }
}
