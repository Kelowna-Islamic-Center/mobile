import 'package:firebase_messaging/firebase_messaging.dart';

class CloudMessagingService {

  // Announcements cloud message receiver
  Future<void> _messageHandler(RemoteMessage message) async {
    print('background message ${message.notification!.body}');
  }

  void init() {
    FirebaseMessaging.onBackgroundMessage(_messageHandler);
    FirebaseMessaging.instance.subscribeToTopic("announcements");
    FirebaseMessaging.instance
        .requestPermission(sound: true, badge: true, alert: true);
  }
}
