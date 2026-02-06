import 'dart:async';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

typedef StompMessageCallback = void Function(Map<String, dynamic> body);

class StompService {
  StompClient? _client;
  final SharedPreferences _prefs;
  final Map<String, StompUnsubscribe?> _subscriptions = {};
  bool _isConnected = false;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  StompService(this._prefs);

  bool get isConnected => _isConnected;
  Stream<bool> get connectionStream => _connectionController.stream;

  void connect({
    VoidCallback? onConnect,
    VoidCallback? onDisconnect,
    Function(StompFrame)? onError,
  }) {
    final token = _prefs.getString(ApiConstants.accessTokenKey) ?? '';

    _client = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onConnect: (StompFrame frame) {
          _isConnected = true;
          _connectionController.add(true);
          onConnect?.call();
          print('[STOMP] Connected');
        },
        onDisconnect: (StompFrame frame) {
          _isConnected = false;
          _connectionController.add(false);
          onDisconnect?.call();
          print('[STOMP] Disconnected');
        },
        onWebSocketError: (dynamic error) {
          print('[STOMP] WebSocket Error: $error');
          _isConnected = false;
          _connectionController.add(false);
        },
        onStompError: (StompFrame frame) {
          print('[STOMP] Error: ${frame.body}');
          onError?.call(frame);
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
  }

  StompUnsubscribe? subscribe(
    String destination,
    void Function(StompFrame) callback,
  ) {
    if (_client == null || !_isConnected) {
      print('[STOMP] Cannot subscribe: not connected');
      return null;
    }

    // Unsubscribe from existing subscription on same destination
    if (_subscriptions.containsKey(destination)) {
      _subscriptions[destination]?.call();
    }

    final unsubscribe = _client!.subscribe(
      destination: destination,
      callback: callback,
    );

    _subscriptions[destination] = unsubscribe;
    print('[STOMP] Subscribed to $destination');
    return unsubscribe;
  }

  void unsubscribe(String destination) {
    if (_subscriptions.containsKey(destination)) {
      _subscriptions[destination]?.call();
      _subscriptions.remove(destination);
      print('[STOMP] Unsubscribed from $destination');
    }
  }

  void send(String destination, String body,
      {Map<String, String>? headers}) {
    if (_client == null || !_isConnected) {
      print('[STOMP] Cannot send: not connected');
      return;
    }
    _client!.send(
      destination: destination,
      body: body,
      headers: headers,
    );
    print('[STOMP] Sent to $destination');
  }

  void disconnect() {
    for (final unsub in _subscriptions.values) {
      unsub?.call();
    }
    _subscriptions.clear();
    _client?.deactivate();
    _isConnected = false;
    _connectionController.add(false);
    print('[STOMP] Disconnecting');
  }

  void dispose() {
    disconnect();
    _connectionController.close();
  }
}
