import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/friend_model.dart';

class FriendRepository {
  final DioClient _client;

  FriendRepository(this._client);

  Future<List<FriendModel>> getFriends() async {
    final response = await _client.get(ApiConstants.friends);
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
        .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFriend(String email) async {
    await _client.post(
      ApiConstants.friends,
      data: {'email': email},
    );
  }

  Future<void> removeFriend(int friendId) async {
    await _client.delete('${ApiConstants.friends}/$friendId');
  }

  Future<void> acceptFriendRequest(int requestId) async {
    await _client.put(
      '${ApiConstants.friendRequests}/$requestId/accept',
    );
  }

  Future<void> rejectFriendRequest(int requestId) async {
    await _client.put(
      '${ApiConstants.friendRequests}/$requestId/reject',
    );
  }

  Future<List<FriendRequest>> getFriendRequests() async {
    final response = await _client.get(ApiConstants.friendRequests);
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
        .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    final response = await _client.get(
      ApiConstants.userSearch,
      queryParameters: {'q': query},
    );
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
        .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
