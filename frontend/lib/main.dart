import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/api_constants.dart';
import 'core/providers/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/providers/chat_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Global key for navigating from notification taps
final globalNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize SharedPreferences before the app starts
  final sharedPreferences = await SharedPreferences.getInstance();

  // Check for notification that launched the app (terminated state)
  RemoteMessage? initialMessage;
  try {
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: LightTalkApp(initialMessage: initialMessage),
    ),
  );
}

class LightTalkApp extends ConsumerStatefulWidget {
  final RemoteMessage? initialMessage;

  const LightTalkApp({super.key, this.initialMessage});

  @override
  ConsumerState<LightTalkApp> createState() => _LightTalkAppState();
}

class _LightTalkAppState extends ConsumerState<LightTalkApp>
    with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FlutterAppBadger.removeBadge();
    _initAndSetupNotifications();
  }

  /// Initialize local notifications FIRST, then set up FCM handlers.
  /// This ensures _localNotifications.show() works when the first message arrives.
  Future<void> _initAndSetupNotifications() async {
    await _initLocalNotifications();
    _notificationsReady = true;
    debugPrint('[FCM] Local notifications initialized, setting up handlers');
    _setupNotificationHandlers();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'chat_messages_v2',
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Request notification permission (Android 13+)
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final chatRoomId = response.payload;
    if (chatRoomId == null || chatRoomId.isEmpty) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString(ApiConstants.accessTokenKey);
    if (token == null || token.isEmpty) return;

    final router = ref.read(routerProvider);
    router.push('/chats/$chatRoomId');
  }

  void _setupNotificationHandlers() {
    // Disable iOS automatic foreground display — we handle it ourselves
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Handle foreground messages — show local notification unless viewing the same room
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message (app was terminated)
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(widget.initialMessage!);
      });
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message received: ${message.data}');
    debugPrint('[FCM] notification: title=${message.notification?.title}, body=${message.notification?.body}');
    debugPrint('[FCM] notificationsReady=$_notificationsReady');

    if (!_notificationsReady) {
      debugPrint('[FCM] Local notifications not initialized yet, skipping');
      return;
    }

    final chatRoomId = message.data['chatRoomId'];
    final activeRoom = ref.read(activeChatRoomProvider);
    debugPrint('[FCM] chatRoomId=$chatRoomId, activeRoom=$activeRoom');

    // Don't show notification if user is viewing this chat room
    if (chatRoomId != null &&
        activeRoom != null &&
        chatRoomId == activeRoom.toString()) {
      debugPrint('[FCM] Suppressed: user is viewing room $chatRoomId');
      return;
    }

    // Extract notification content (try notification payload, fallback to data)
    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) {
      debugPrint('[FCM] No title/body, skipping display');
      return;
    }

    debugPrint('[FCM] Showing local notification: $title - $body');

    try {
      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages_v2',
            'Chat Messages',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: chatRoomId,
      );
      debugPrint('[FCM] Local notification shown successfully');
    } catch (e) {
      debugPrint('[FCM] Failed to show local notification: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final chatRoomId = message.data['chatRoomId'];
    if (chatRoomId == null || chatRoomId.isEmpty) return;

    // Check if user is logged in
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString(ApiConstants.accessTokenKey);
    if (token == null || token.isEmpty) return;

    final router = ref.read(routerProvider);
    router.push('/chats/$chatRoomId');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FlutterAppBadger.removeBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Light Talk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
