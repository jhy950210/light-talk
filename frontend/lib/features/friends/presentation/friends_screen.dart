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
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/friends/add'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: state.isLoading && state.friends.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.friends.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(friendsProvider.notifier).loadFriends(),
                  child: _buildFriendsList(context, state),
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
              'No friends yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to start chatting!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC7C7CC),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/friends/add'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Friend'),
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
              context, 'Online', onlineFriends.length.toString()),
          ...onlineFriends.map((f) => _buildFriendTile(context, f)),
        ],
        if (offlineFriends.isNotEmpty) ...[
          _buildSectionHeader(
              context, 'Offline', offlineFriends.length.toString()),
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
                  color: const Color(0xFF8E8E93),
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
                    color: const Color(0xFF8E8E93),
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
            title: const Text('Remove Friend'),
            content: Text(
                'Are you sure you want to remove ${friend.nickname}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed),
                child: const Text('Remove'),
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
          friend.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 13,
            color: friend.isOnline
                ? AppTheme.onlineGreen
                : const Color(0xFFC7C7CC),
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
