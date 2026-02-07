import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/chat_room_model.dart';
import 'models/message_model.dart';

class ChatRepository {
  final DioClient _client;

  ChatRepository(this._client);

  Future<List<ChatRoomModel>> getChatRooms() async {
    final response = await _client.get(ApiConstants.chats);
    final data = response.data;

    List<dynamic> list;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      list = data['data'] as List<dynamic>? ?? [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list
        .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatRoomModel> getChatRoom(int roomId) async {
    final response =
        await _client.get(ApiConstants.chatRoom(roomId));
    final data = response.data;

    final json = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;

    return ChatRoomModel.fromJson(json);
  }

  Future<ChatRoomModel> createDirectChatRoom(int friendId) async {
    final response = await _client.post(
      ApiConstants.chats,
      data: {
        'targetUserId': friendId,
      },
    );
    final data = response.data;
    final json = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;

    return ChatRoomModel.fromJson(json);
  }

  /// Fetch messages with cursor-based pagination.
  /// [cursor] = fetch messages older than this ID.
  /// [size] = number of messages to fetch.
  Future<MessagePage> getMessages(
    int roomId, {
    int? cursor,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'size': size,
    };
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }

    final response = await _client.get(
      ApiConstants.messages(roomId),
      queryParameters: queryParams,
    );
    final data = response.data;

    Map<String, dynamic> pageData;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      pageData = data['data'] as Map<String, dynamic>? ?? data;
    } else {
      pageData = data as Map<String, dynamic>;
    }

    // Handle both flat list and paged response
    if (pageData.containsKey('content')) {
      final messages = (pageData['content'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return MessagePage(
        messages: messages,
        hasMore: pageData['hasNext'] as bool? ??
            pageData['hasMore'] as bool? ??
            false,
        nextCursor: pageData['nextCursor'] as int?,
      );
    }

    // If response is a flat list
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      final messages = list
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return MessagePage(
        messages: messages,
        hasMore: messages.length >= size,
        nextCursor: messages.isNotEmpty ? messages.last.id : null,
      );
    }

    return const MessagePage(messages: [], hasMore: false);
  }

  Future<void> markAsRead(int roomId, int messageId) async {
    await _client.put(
      ApiConstants.readReceipt(roomId),
      data: {'messageId': messageId},
    );
  }
}

class MessagePage {
  final List<MessageModel> messages;
  final bool hasMore;
  final int? nextCursor;

  const MessagePage({
    required this.messages,
    required this.hasMore,
    this.nextCursor,
  });
}
