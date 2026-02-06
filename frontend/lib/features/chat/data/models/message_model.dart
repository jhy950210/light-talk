class MessageModel {
  final int id;
  final int chatRoomId;
  final int senderId;
  final String senderNickname;
  final String? senderProfileImageUrl;
  final String content;
  final String type;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderNickname,
    this.senderProfileImageUrl,
    required this.content,
    this.type = 'TEXT',
    required this.createdAt,
  });

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
      };

  bool isSentBy(int userId) => senderId == userId;
}
