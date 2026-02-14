import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../friends/data/models/friend_model.dart';
import '../../friends/providers/friends_provider.dart';
import '../providers/chat_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _isCreating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(friendsProvider.notifier).loadFriends();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FriendModel> _filteredFriends(List<FriendModel> friends) {
    if (_searchQuery.isEmpty) return friends;
    final q = _searchQuery.toLowerCase();
    return friends
        .where((f) =>
            f.nickname.toLowerCase().contains(q) ||
            f.displayName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _createGroup() async {
    if (_selectedIds.length < 2) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('그룹 이름을 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final room = await ref.read(chatRoomsProvider.notifier).createGroupRoom(
            name: name,
            memberIds: _selectedIds.toList(),
          );
      if (mounted) {
        context.pushReplacement('/chats/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('그룹 채팅방 생성에 실패했습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);
    final friends = _filteredFriends(friendsState.friends);

    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 채팅 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed:
                _selectedIds.length >= 2 && !_isCreating ? _createGroup : null,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '만들기 (${_selectedIds.length})',
                    style: TextStyle(
                      color: _selectedIds.length >= 2
                          ? AppTheme.primaryColor
                          : AppTheme.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group name input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '그룹 이름',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
          ),

          // Selected friends chips
          if (_selectedIds.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: _selectedIds.map((id) {
                  final friend = friendsState.friends
                      .where((f) => f.id == id)
                      .toList();
                  if (friend.isEmpty) return const SizedBox.shrink();
                  final f = friend.first;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      avatar: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryLight.withValues(alpha: 0.3),
                        child: Text(
                          f.nickname.isNotEmpty
                              ? f.nickname[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                      label: Text(f.nickname),
                      onDeleted: () {
                        setState(() => _selectedIds.remove(id));
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '친구 검색',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Minimum selection hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '2명 이상의 친구를 선택해주세요',
              style: TextStyle(
                fontSize: 13,
                color: _selectedIds.length < 2
                    ? AppTheme.textSecondary
                    : AppTheme.onlineGreen,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Friends list
          Expanded(
            child: friendsState.isLoading && friendsState.friends.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : friends.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? '검색 결과가 없습니다'
                              : '친구가 없습니다',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final isSelected = _selectedIds.contains(friend.id);
                          return _FriendSelectTile(
                            friend: friend,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(friend.id);
                                } else {
                                  _selectedIds.add(friend.id);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FriendSelectTile extends StatelessWidget {
  final FriendModel friend;
  final bool isSelected;
  final VoidCallback onTap;

  const _FriendSelectTile({
    required this.friend,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: AvatarWidget(
        name: friend.nickname,
        imageUrl: friend.profileImageUrl,
        radius: 22,
        showOnlineIndicator: true,
        isOnline: friend.isOnline,
      ),
      title: Text(
        friend.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
        size: 24,
      ),
      onTap: onTap,
    );
  }
}
