import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../data/friend_repository.dart';
import '../data/models/friend_model.dart';

// ── Friends State ────────────────────────────────────────────
class FriendsState {
  final List<FriendModel> friends;
  final bool isLoading;
  final String? errorMessage;

  const FriendsState({
    this.friends = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FriendsState copyWith({
    List<FriendModel>? friends,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ── Friends Notifier ─────────────────────────────────────────
class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendRepository _repository;

  FriendsNotifier(this._repository) : super(const FriendsState());

  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final friends = await _repository.getFriends();
      // Sort: online friends first, then alphabetical
      friends.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return a.isOnline ? -1 : 1;
        }
        return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
      });
      state = state.copyWith(friends: friends, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<bool> addFriend(int friendId) async {
    try {
      await _repository.addFriend(friendId);
      await loadFriends();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
      return false;
    }
  }

  Future<void> removeFriend(int friendId) async {
    try {
      await _repository.removeFriend(friendId);
      state = state.copyWith(
        friends: state.friends.where((f) => f.id != friendId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic> && error['message'] != null) {
          return error['message'] as String;
        }
      }
      return 'Server error. Please try again.';
    }
    return 'An unexpected error occurred.';
  }

  void updateOnlineStatus(int userId, bool isOnline) {
    final updated = state.friends.map((f) {
      if (f.id == userId) return f.copyWith(isOnline: isOnline);
      return f;
    }).toList();
    state = state.copyWith(friends: updated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ── Search State ─────────────────────────────────────────────
class UserSearchState {
  final List<UserSearchResult> results;
  final bool isSearching;
  final String? errorMessage;

  const UserSearchState({
    this.results = const [],
    this.isSearching = false,
    this.errorMessage,
  });

  UserSearchState copyWith({
    List<UserSearchResult>? results,
    bool? isSearching,
    String? errorMessage,
  }) {
    return UserSearchState(
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }
}

class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final FriendRepository _repository;

  UserSearchNotifier(this._repository) : super(const UserSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const UserSearchState();
      return;
    }
    state = state.copyWith(isSearching: true, errorMessage: null);
    try {
      final results = await _repository.searchUsers(query.trim());
      state = state.copyWith(results: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: _parseError(e),
      );
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic> && error['message'] != null) {
          return error['message'] as String;
        }
      }
      return 'Server error. Please try again.';
    }
    return 'An unexpected error occurred.';
  }

  void clear() {
    state = const UserSearchState();
  }
}

// ── Providers ────────────────────────────────────────────────
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(ref.watch(dioClientProvider));
});

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier(ref.watch(friendRepositoryProvider));
});

final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  return UserSearchNotifier(ref.watch(friendRepositoryProvider));
});
