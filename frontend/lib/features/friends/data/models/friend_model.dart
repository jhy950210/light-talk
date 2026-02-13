class FriendModel {
  final int id;
  final String nickname;
  final String tag;
  final String? profileImageUrl;
  final bool isOnline;

  const FriendModel({
    required this.id,
    required this.nickname,
    this.tag = '',
    this.profileImageUrl,
    this.isOnline = false,
  });

  String get displayName => '$nickname#$tag';

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as int? ?? json['friendId'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'tag': tag,
        'profileImageUrl': profileImageUrl,
        'isOnline': isOnline,
      };

  FriendModel copyWith({
    int? id,
    String? nickname,
    String? tag,
    String? profileImageUrl,
    bool? isOnline,
  }) {
    return FriendModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      tag: tag ?? this.tag,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class FriendRequest {
  final int id;
  final int friendshipId;
  final String nickname;
  final String tag;
  final String? profileImageUrl;

  const FriendRequest({
    required this.id,
    required this.friendshipId,
    required this.nickname,
    this.tag = '',
    this.profileImageUrl,
  });

  String get displayName => '$nickname#$tag';

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int? ?? 0,
      friendshipId: json['friendshipId'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}

class UserSearchResult {
  final int id;
  final String nickname;
  final String tag;
  final String? profileImageUrl;

  const UserSearchResult({
    required this.id,
    required this.nickname,
    this.tag = '',
    this.profileImageUrl,
  });

  String get displayName => '$nickname#$tag';

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
