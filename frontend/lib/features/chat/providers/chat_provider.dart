import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/stomp_service.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/error_utils.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_room_model.dart';
import '../data/models/message_model.dart';

// ═══════════════════════════════════════════════════════════════
// Chat Rooms Provider
// ═══════════════════════════════════════════════════════════════

class ChatRoomsState {
  final List<ChatRoomModel> rooms;
  final bool isLoading;
  final String? errorMessage;

  const ChatRoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatRoomsState copyWith({
    List<ChatRoomModel>? rooms,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatRoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChatRoomsNotifier extends StateNotifier<ChatRoomsState> {
  final ChatRepository _repository;
  final StompService _stompService;
  final SharedPreferences _prefs;
  StreamSubscription<bool>? _connectionSub;

  ChatRoomsNotifier(this._repository, this._stompService, this._prefs)
      : super(const ChatRoomsState()) {
    _subscribeToUserQueue();
    // Listen for STOMP (re)connections to re-subscribe
    _connectionSub = _stompService.connectionStream.listen((connected) {
      if (connected) {
        _subscribeToUserQueue();
        loadRooms();
      }
    });
  }

  void _subscribeToUserQueue() {
    final userId = _prefs.getInt(ApiConstants.userIdKey);
    if (userId != null && _stompService.isConnected) {
      _stompService.subscribe(
        ApiConstants.queueUser(userId),
        _onUserQueueMessage,
      );
    }
  }

  void _onUserQueueMessage(StompFrame frame) {
    if (frame.body == null) return;
    try {
      final data = jsonDecode(frame.body!) as Map<String, dynamic>;
      final eventType = data['type'] as String?;
      if (eventType == 'NEW_MESSAGE' ||
          eventType == 'MESSAGE_DELETED' ||
          eventType == 'MEMBER_JOINED' ||
          eventType == 'MEMBER_LEFT' ||
          eventType == 'MEMBER_KICKED' ||
          eventType == 'ROOM_UPDATED') {
        loadRooms();
      }
    } catch (_) {}
  }

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rooms = await _repository.getChatRooms();
      // Sort by last message time, most recent first
      rooms.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.createdAt;
        final bTime = b.lastMessage?.createdAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: parseApiError(e),
      );
    }
  }

  Future<ChatRoomModel> createDirectRoom(int friendId) async {
    final room = await _repository.createDirectChatRoom(friendId);
    await loadRooms();
    return room;
  }

  Future<ChatRoomModel> createGroupRoom({
    required String name,
    required List<int> memberIds,
  }) async {
    final room = await _repository.createGroupChatRoom(
      name: name,
      memberIds: memberIds,
    );
    await loadRooms();
    return room;
  }

  void updateRoomLastMessage(int roomId, MessageModel message) {
    final updated = state.rooms.map((r) {
      if (r.id == roomId) {
        return r.copyWith(
          lastMessage: LastMessage(
            id: message.id,
            content: message.content,
            senderNickname: message.senderNickname,
            senderId: message.senderId,
            type: message.type,
            createdAt: message.createdAt,
          ),
        );
      }
      return r;
    }).toList();
    state = state.copyWith(rooms: updated);
  }

  Future<void> leaveRoom(int roomId) async {
    try {
      await _repository.leaveRoom(roomId);
      state = state.copyWith(
        rooms: state.rooms.where((r) => r.id != roomId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: parseApiError(e));
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// Messages Provider (per chat room)
// ═══════════════════════════════════════════════════════════════

class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final bool isUploading;
  final double uploadProgress;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ChatRepository _repository;
  final StompService _stompService;
  final int roomId;
  StompUnsubscribe? _unsubscribe;
  StreamSubscription<bool>? _connectionSub;
  bool _isSubscribed = false;

  MessagesNotifier(this._repository, this._stompService, this.roomId)
      : super(const MessagesState());

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _repository.getMessages(roomId);
      state = state.copyWith(
        messages: page.messages,
        isLoading: false,
        hasMore: page.hasMore,
      );
      markAsRead();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: parseApiError(e),
      );
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore || state.messages.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final oldestId = state.messages.last.id;
      final page = await _repository.getMessages(
        roomId,
        cursor: oldestId,
      );
      state = state.copyWith(
        messages: [...state.messages, ...page.messages],
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void subscribeToRoom() {
    _isSubscribed = true;
    if (_stompService.isConnected) {
      _unsubscribe = _stompService.subscribe(
        ApiConstants.topicChat(roomId),
        _onMessage,
      );
    }
    // Re-subscribe on STOMP reconnection
    _connectionSub?.cancel();
    _connectionSub = _stompService.connectionStream.listen((connected) {
      if (connected && _isSubscribed) {
        _unsubscribe = _stompService.subscribe(
          ApiConstants.topicChat(roomId),
          _onMessage,
        );
        // Reload messages to catch any missed during disconnect
        loadMessages();
      }
    });
  }

  void _onMessage(StompFrame frame) {
    if (frame.body == null) return;
    try {
      final data = jsonDecode(frame.body!) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      if (eventType == 'MESSAGE_DELETED') {
        final messageId = data['messageId'] as int;
        _markMessageAsDeleted(messageId);
        return;
      }

      if (eventType == 'NEW_MESSAGE') {
        final messageData = data['message'] as Map<String, dynamic>;
        final message = MessageModel.fromJson(messageData);
        // Add to the beginning (newest first)
        final existing = state.messages.any((m) => m.id == message.id);
        if (!existing) {
          state = state.copyWith(
            messages: [message, ...state.messages],
          );
          // Mark as read since user is viewing this room
          markAsRead();
        }
        return;
      }

      if (eventType == 'READ_RECEIPT') {
        final messageId = data['messageId'] as int;
        _markMessagesAsRead(messageId);
        return;
      }

      // Ignore other event types (MEMBER_JOINED, etc.)
      print('[Chat] Ignoring event type: $eventType');
    } catch (e) {
      print('[Chat] Failed to parse STOMP message: $e');
    }
  }

  void _markMessagesAsRead(int upToMessageId) {
    final updated = state.messages.map((m) {
      if (m.id <= upToMessageId && !m.isRead) {
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  void _markMessageAsDeleted(int messageId) {
    final updated = state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWithDeleted();
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _repository.deleteMessage(roomId, messageId);
      _markMessageAsDeleted(messageId);
    } catch (e) {
      state = state.copyWith(errorMessage: parseApiError(e));
    }
  }

  void sendMessage(String content, int senderId, String senderNickname, {String type = 'TEXT'}) {
    final payload = jsonEncode({
      'content': content,
      'type': type,
    });
    _stompService.send(ApiConstants.appChatSend(roomId), payload);
  }

  Future<void> sendMediaMessage({
    required File file,
    required String contentType,
    required String messageType,
    required int senderId,
    required String senderNickname,
  }) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, errorMessage: null);
    try {
      final fileName = file.path.split('/').last;
      final fileLength = await file.length();
      final purpose = messageType == 'VIDEO' ? 'CHAT_VIDEO' : 'CHAT_IMAGE';

      // 1. Get presigned URL
      final presign = await _repository.getPresignedUrl(
        fileName: fileName,
        contentType: contentType,
        contentLength: fileLength,
        purpose: purpose,
        chatRoomId: roomId,
      );

      // 2. Upload to R2
      await _repository.uploadToR2(
        uploadUrl: presign.uploadUrl,
        file: file,
        contentType: contentType,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      // 3. Send message via STOMP
      sendMessage(presign.publicUrl, senderId, senderNickname, type: messageType);

      state = state.copyWith(isUploading: false, uploadProgress: 0.0);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        errorMessage: parseApiError(e),
      );
    }
  }

  void unsubscribeFromRoom() {
    _isSubscribed = false;
    _connectionSub?.cancel();
    _connectionSub = null;
    _unsubscribe?.call();
    _unsubscribe = null;
    _stompService.unsubscribe(ApiConstants.topicChat(roomId));
  }

  Future<void> markAsRead() async {
    if (state.messages.isNotEmpty) {
      try {
        await _repository.markAsRead(roomId, state.messages.first.id);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    unsubscribeFromRoom();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioClientProvider));
});

final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, ChatRoomsState>((ref) {
  return ChatRoomsNotifier(
    ref.watch(chatRepositoryProvider),
    ref.watch(stompServiceProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

/// Family provider: one MessagesNotifier per room
final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    MessagesState, int>((ref, roomId) {
  return MessagesNotifier(
    ref.watch(chatRepositoryProvider),
    ref.watch(stompServiceProvider),
    roomId,
  );
});

// ═══════════════════════════════════════════════════════════════
// Chat Members Provider (for group management)
// ═══════════════════════════════════════════════════════════════

class ChatMembersState {
  final List<ChatMember> members;
  final bool isLoading;
  final String? errorMessage;

  const ChatMembersState({
    this.members = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatMembersState copyWith({
    List<ChatMember>? members,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChatMembersNotifier extends StateNotifier<ChatMembersState> {
  final ChatRepository _repository;
  final int roomId;

  ChatMembersNotifier(this._repository, this.roomId)
      : super(const ChatMembersState());

  Future<void> loadMembers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final members = await _repository.getChatMembers(roomId);
      state = state.copyWith(members: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: parseApiError(e),
      );
    }
  }

  Future<bool> inviteMembers(List<int> userIds) async {
    try {
      await _repository.inviteMembers(roomId, userIds);
      await loadMembers();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: parseApiError(e));
      return false;
    }
  }

  Future<bool> kickMember(int userId) async {
    try {
      await _repository.kickMember(roomId, userId);
      state = state.copyWith(
        members: state.members.where((m) => m.userId != userId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: parseApiError(e));
      return false;
    }
  }

  Future<bool> leaveRoom() async {
    try {
      await _repository.leaveRoom(roomId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: parseApiError(e));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final chatMembersProvider = StateNotifierProvider.family<ChatMembersNotifier,
    ChatMembersState, int>((ref, roomId) {
  return ChatMembersNotifier(
    ref.watch(chatRepositoryProvider),
    roomId,
  );
});
