import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../../data/repositories/device_tokens_repository.dart';

class PushService {
  PushService(this._tokens);

  final DeviceTokensRepository _tokens;
  String? _currentToken;
  String? _currentMemberId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Registered by the app shell; receives the data payload of a tapped
  /// notification (cold start or background tap).
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Registered by the app shell; receives foreground messages to render as
  /// an in-app banner/snackbar.
  static void Function(RemoteMessage message)? onForegroundMessage;

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

    _currentMemberId = memberId;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    if (kIsWeb && Env.firebaseVapidKey.isNotEmpty) {
      await messaging.getToken(vapidKey: Env.firebaseVapidKey);
    }
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;

    _currentToken = token;
    await _tokens.upsert(memberId: memberId, token: token);

    // Re-upsert whenever FCM rotates the token.
    _tokenRefreshSub ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final member = _currentMemberId;
      if (member == null || newToken.isEmpty) return;
      _currentToken = newToken;
      try {
        await _tokens.upsert(memberId: member, token: newToken);
      } catch (e) {
        debugPrint('Token refresh upsert failed: $e');
      }
    });

    _setupMessageHandlers();
  }

  void _setupMessageHandlers() {
    // Cold start: app launched by tapping a notification.
    unawaited(
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) _dispatchTap(message);
      }),
    );

    // Background -> foreground via notification tap.
    _openedAppSub ??=
        FirebaseMessaging.onMessageOpenedApp.listen(_dispatchTap);

    // Foreground messages: show in-app banner via the registered callback.
    _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
      onForegroundMessage?.call(message);
    });
  }

  void _dispatchTap(RemoteMessage message) {
    final handler = onNotificationTap;
    if (handler == null) return;
    try {
      handler(Map<String, dynamic>.from(message.data));
    } catch (e) {
      debugPrint('Notification tap handling failed: $e');
    }
  }

  /// Deletes the device token server-side; call BEFORE destroying the session.
  Future<void> unregister() async {
    if (!Env.isFirebaseConfigured) return;
    final token = _currentToken;
    final memberId = _currentMemberId;
    _currentToken = null;
    _currentMemberId = null;
    unawaited(_tokenRefreshSub?.cancel());
    _tokenRefreshSub = null;
    unawaited(_openedAppSub?.cancel());
    _openedAppSub = null;
    unawaited(_foregroundSub?.cancel());
    _foregroundSub = null;
    if (token == null || memberId == null) return;
    try {
      await _tokens.deleteToken(memberId: memberId, token: token);
    } catch (e) {
      debugPrint('Device token delete failed: $e');
    }
  }
}
