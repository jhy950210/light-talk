import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../providers/friends_provider.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(friendsProvider.notifier).loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    ref.listen<FriendsState>(friendsProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(friendsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/friends/add'),
          ),
        ],
      ),
      body: state.isLoading && state.friends.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.friends.isEmpty
              ? _buildErrorState(context, state.errorMessage!)
              : state.friends.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(friendsProvider.notifier).loadFriends(),
                      child: _buildFriendsList(context, state),
                    ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(friendsProvider.notifier).loadFriends(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 친구가 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '친구를 추가하고 대화를 시작하세요!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/friends/add'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('친구 추가'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context, FriendsState state) {
    final onlineFriends =
        state.friends.where((f) => f.isOnline).toList();
    final offlineFriends =
        state.friends.where((f) => !f.isOnline).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (onlineFriends.isNotEmpty) ...[
          _buildSectionHeader(
              context, '온라인', onlineFriends.length.toString()),
          ...onlineFriends.map((f) => _buildFriendTile(context, f)),
        ],
        if (offlineFriends.isNotEmpty) ...[
          _buildSectionHeader(
              context, '오프라인', offlineFriends.length.toString()),
          ...offlineFriends.map((f) => _buildFriendTile(context, f)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, dynamic friend) {
    return Dismissible(
      key: ValueKey(friend.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('친구 삭제'),
            content: Text(
                '${friend.nickname} 님을 친구에서 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(friendsProvider.notifier).removeFriend(friend.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorRed,
        child: const Icon(Icons.delete_outlined, color: Colors.white),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: AvatarWidget(
          name: friend.nickname,
          imageUrl: friend.profileImageUrl,
          radius: 24,
          showOnlineIndicator: true,
          isOnline: friend.isOnline,
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          friend.isOnline ? '온라인' : '오프라인',
          style: TextStyle(
            fontSize: 13,
            color: friend.isOnline
                ? AppTheme.onlineGreen
                : AppTheme.textTertiary,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
          color: AppTheme.primaryColor,
          onPressed: () {
            // Navigate to or create direct chat with this friend
            context.push('/chats/new?friendId=${friend.id}');
          },
        ),
        onTap: () {
          context.push('/chats/new?friendId=${friend.id}');
        },
      ),
    );
  }
}
