import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../network/stomp_service.dart';

/// SharedPreferences instance — must be initialized before runApp
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'SharedPreferences must be overridden in ProviderScope');
});

/// Dio HTTP client
final dioClientProvider = Provider<DioClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DioClient(prefs);
});

/// STOMP WebSocket service
final stompServiceProvider = Provider<StompService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = StompService(prefs);
  ref.onDispose(() => service.dispose());
  return service;
});
