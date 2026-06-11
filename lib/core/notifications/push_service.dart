import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../../data/repositories/device_tokens_repository.dart';

class PushService {
  PushService(this._tokens);

  final DeviceTokensRepository _tokens;
  String? _currentToken;

  static Future<void> init() async {
    if (!Env.isFirebaseConfigured) return;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: Env.firebaseApiKey,
        appId: Env.firebaseAppId,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
      ),
    );
  }

  Future<void> registerForMember(String memberId) async {
    if (!Env.isFirebaseConfigured) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    if (kIsWeb && Env.firebaseVapidKey.isNotEmpty) {
      await messaging.getToken(vapidKey: Env.firebaseVapidKey);
    }
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;

    _currentToken = token;
    await _tokens.upsert(memberId: memberId, token: token);
  }

  Future<void> unregister() async {
    if (!Env.isFirebaseConfigured) return;
    final token = _currentToken;
    if (token == null) return;
    _currentToken = null;
  }
}
