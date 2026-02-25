import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
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

  void Function()? _onConnectCallback;
  void Function()? _onDisconnectCallback;
  Function(StompFrame)? _onErrorCallback;

  void connect({
    void Function()? onConnect,
    void Function()? onDisconnect,
    Function(StompFrame)? onError,
  }) {
    _onConnectCallback = onConnect;
    _onDisconnectCallback = onDisconnect;
    _onErrorCallback = onError;
    _connectWithCurrentToken();
  }

  void _connectWithCurrentToken() {
    // Always read the latest token
    final token = _prefs.getString(ApiConstants.accessTokenKey) ?? '';
    if (token.isEmpty) {
      print('[STOMP] No token available, skipping connect');
      return;
    }

    // Deactivate existing client
    _client?.deactivate();

    final onConnectCb = (StompFrame frame) {
      _isConnected = true;
      _connectionController.add(true);
      _onConnectCallback?.call();
      print('[STOMP] Connected');
    };
    final onDisconnectCb = (StompFrame frame) {
      _isConnected = false;
      _connectionController.add(false);
      _onDisconnectCallback?.call();
      print('[STOMP] Disconnected');
    };
    final onWebSocketErrorCb = (dynamic error) {
      print('[STOMP] WebSocket Error: $error');
      _isConnected = false;
      _connectionController.add(false);
      // Reconnect with fresh token after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          print('[STOMP] Reconnecting with fresh token...');
          _connectWithCurrentToken();
        }
      });
    };
    final onStompErrorCb = (StompFrame frame) {
      print('[STOMP] Error: ${frame.body}');
      _onErrorCallback?.call(frame);
      // Reconnect with fresh token after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          print('[STOMP] Reconnecting with fresh token after error...');
          _connectWithCurrentToken();
        }
      });
    };

    // Web uses SockJS endpoint (/ws), mobile uses raw WebSocket (/ws/raw)
    final config = kIsWeb
        ? StompConfig.sockJS(
            url: ApiConstants.wsUrlSockJS,
            stompConnectHeaders: {'Authorization': 'Bearer $token'},
            webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
            onConnect: onConnectCb,
            onDisconnect: onDisconnectCb,
            onWebSocketError: onWebSocketErrorCb,
            onStompError: onStompErrorCb,
            reconnectDelay: const Duration(seconds: 0), // We handle reconnection ourselves
          )
        : StompConfig(
            url: ApiConstants.wsUrl,
            stompConnectHeaders: {'Authorization': 'Bearer $token'},
            webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
            onConnect: onConnectCb,
            onDisconnect: onDisconnectCb,
            onWebSocketError: onWebSocketErrorCb,
            onStompError: onStompErrorCb,
            reconnectDelay: const Duration(seconds: 0), // We handle reconnection ourselves
          );

    _client = StompClient(config: config);
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
