import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../data/models/friend_model.dart';
import '../providers/friends_provider.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(friendRequestsProvider.notifier).loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendRequestsProvider);

    ref.listen<FriendRequestsState>(friendRequestsProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(friendRequestsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 신청'),
      ),
      body: state.isLoading && state.requests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.requests.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(friendRequestsProvider.notifier).loadRequests(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.requests.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _buildRequestTile(context, state.requests[index]);
                    },
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
              Icons.person_add_disabled_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '받은 친구 신청이 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 친구 신청이 오면 여기에 표시됩니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC7C7CC),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTile(BuildContext context, FriendRequest request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          AvatarWidget(
            name: request.nickname,
            imageUrl: request.profileImageUrl,
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              request.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _rejectRequest(request),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8E8E93),
              side: const BorderSide(color: Color(0xFFE5E5EA)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('거절', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _acceptRequest(request),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('수락', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final success =
        await ref.read(friendRequestsProvider.notifier).acceptRequest(request.friendshipId);
    if (success) {
      ref.read(friendsProvider.notifier).loadFriends();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 신청을 수락했습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('친구 신청 거절'),
        content: const Text('이 친구 신청을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('거절'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(friendRequestsProvider.notifier)
          .rejectRequest(request.friendshipId);
    }
  }
}
