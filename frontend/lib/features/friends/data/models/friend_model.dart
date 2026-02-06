class FriendModel {
  final int id;
  final String nickname;
  final String? profileImageUrl;
  final bool isOnline;
  final String email;

  const FriendModel({
    required this.id,
    required this.nickname,
    this.profileImageUrl,
    this.isOnline = false,
    this.email = '',
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as int? ?? json['friendId'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['online'] as bool? ?? false,
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
        'isOnline': isOnline,
        'email': email,
      };

  FriendModel copyWith({
    int? id,
    String? nickname,
    String? profileImageUrl,
    bool? isOnline,
    String? email,
  }) {
    return FriendModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
      email: email ?? this.email,
    );
  }
}

class FriendRequest {
  final int id;
  final int fromUserId;
  final String fromNickname;
  final String? fromProfileImageUrl;
  final String status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromNickname,
    this.fromProfileImageUrl,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int? ?? 0,
      fromUserId: json['fromUserId'] as int? ?? json['userId'] as int? ?? 0,
      fromNickname: json['fromNickname'] as String? ??
          json['nickname'] as String? ??
          '',
      fromProfileImageUrl: json['fromProfileImageUrl'] as String? ??
          json['profileImageUrl'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class UserSearchResult {
  final int id;
  final String email;
  final String nickname;
  final String? profileImageUrl;

  const UserSearchResult({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
