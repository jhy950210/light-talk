class ChatRoomModel {
  final int id;
  final String type;
  final String name;
  final String? imageUrl;
  final LastMessage? lastMessage;
  final int unreadCount;
  final List<ChatMember> members;
  final DateTime createdAt;

  const ChatRoomModel({
    required this.id,
    required this.type,
    required this.name,
    this.imageUrl,
    this.lastMessage,
    this.unreadCount = 0,
    this.members = const [],
    required this.createdAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'DIRECT',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => ChatMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  ChatRoomModel copyWith({
    int? id,
    String? type,
    String? name,
    String? imageUrl,
    LastMessage? lastMessage,
    int? unreadCount,
    List<ChatMember>? members,
    DateTime? createdAt,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LastMessage {
  final int id;
  final String content;
  final String senderNickname;
  final int senderId;
  final String type;
  final DateTime createdAt;

  const LastMessage({
    required this.id,
    required this.content,
    required this.senderNickname,
    required this.senderId,
    this.type = 'TEXT',
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      senderNickname: json['senderNickname'] as String? ?? '',
      senderId: json['senderId'] as int? ?? 0,
      type: json['type'] as String? ?? 'TEXT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class ChatMember {
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final bool isOnline;

  const ChatMember({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    this.isOnline = false,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      userId: json['userId'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}
