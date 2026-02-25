class MessageModel {
  final int id;
  final int chatRoomId;
  final int senderId;
  final String senderNickname;
  final String? senderProfileImageUrl;
  final String content;
  final String type;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderNickname,
    this.senderProfileImageUrl,
    required this.content,
    this.type = 'TEXT',
    required this.createdAt,
    this.deletedAt,
    this.isRead = false,
  });

  bool get isDeleted => deletedAt != null;
  bool get isImage => type == 'IMAGE';
  bool get isVideo => type == 'VIDEO';
  bool get isMedia => isImage || isVideo;
  String get mediaUrl => content;

  bool canBeDeletedBy(int userId) {
    if (senderId != userId) return false;
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return createdAt.isAfter(fiveMinutesAgo);
  }

  MessageModel copyWith({bool? isRead}) {
    return MessageModel(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderNickname: senderNickname,
      senderProfileImageUrl: senderProfileImageUrl,
      content: content,
      type: type,
      createdAt: createdAt,
      deletedAt: deletedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  MessageModel copyWithDeleted() {
    return MessageModel(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderNickname: senderNickname,
      senderProfileImageUrl: senderProfileImageUrl,
      content: '',
      type: type,
      createdAt: createdAt,
      deletedAt: DateTime.now(),
      isRead: isRead,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int? ?? 0,
      chatRoomId: json['chatRoomId'] as int? ?? 0,
      senderId: json['senderId'] as int? ?? 0,
      senderNickname: json['senderNickname'] as String? ?? '',
      senderProfileImageUrl: json['senderProfileImageUrl'] as String?,
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'TEXT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'senderNickname': senderNickname,
        'senderProfileImageUrl': senderProfileImageUrl,
        'content': content,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'isRead': isRead,
      };

  bool isSentBy(int userId) => senderId == userId;
}
