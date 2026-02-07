import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_input_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_room_screen.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/friends/presentation/add_friend_screen.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Only watch isLoggedIn to avoid router recreation on OTP flow state changes
  final isLoggedIn = ref.watch(authProvider.select((s) => s.isLoggedIn));

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/friends',
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/register/phone' ||
          state.matchedLocation == '/register/otp';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/friends';
      }
      return null;
    },
    routes: [
      // ── Auth Routes ────────────────────────────
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register/phone',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/register/otp',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main Shell (Bottom Navigation) ─────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/friends',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FriendsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddFriendScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/chats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
        ],
      ),

      // ── Settings (full screen, outside shell) ──
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Chat Room (full screen, outside shell) ──
      GoRoute(
        path: '/chats/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final friendIdStr = state.uri.queryParameters['friendId'];
          final friendId = int.tryParse(friendIdStr ?? '') ?? 0;
          return _CreateChatRedirect(friendId: friendId);
        },
      ),
      GoRoute(
        path: '/chats/:roomId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final roomId =
              int.tryParse(state.pathParameters['roomId'] ?? '') ?? 0;
          return ChatRoomScreen(roomId: roomId);
        },
      ),
    ],
  );
});

/// Helper widget that creates a direct chat room and redirects to it.
class _CreateChatRedirect extends ConsumerStatefulWidget {
  final int friendId;

  const _CreateChatRedirect({required this.friendId});

  @override
  ConsumerState<_CreateChatRedirect> createState() =>
      _CreateChatRedirectState();
}

class _CreateChatRedirectState extends ConsumerState<_CreateChatRedirect> {
  @override
  void initState() {
    super.initState();
    _createAndNavigate();
  }

  Future<void> _createAndNavigate() async {
    try {
      final notifier = ref.read(chatRoomsProvider.notifier);
      final room = await notifier.createDirectRoom(widget.friendId);
      if (mounted) {
        context.go('/chats/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat room.')),
        );
        context.go('/friends');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
