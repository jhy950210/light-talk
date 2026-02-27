import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/api_constants.dart';
import 'core/providers/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FlutterAppBadger.removeBadge();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message (app was terminated)
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(widget.initialMessage!);
      });
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
