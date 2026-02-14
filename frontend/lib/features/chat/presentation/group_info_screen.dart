import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../friends/data/models/friend_model.dart';
import '../../friends/providers/friends_provider.dart';
import '../data/models/chat_room_model.dart';
import '../providers/chat_provider.dart';

class GroupInfoScreen extends ConsumerStatefulWidget {
  final int roomId;

  const GroupInfoScreen({super.key, required this.roomId});

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  int get _currentUserId =>
      ref.read(sharedPreferencesProvider).getInt(ApiConstants.userIdKey) ?? 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatMembersProvider(widget.roomId).notifier).loadMembers();
    });
  }

  bool _isCurrentUserAdmin(List<ChatMember> members) {
    final me = members.where((m) => m.userId == _currentUserId).toList();
    return me.isNotEmpty && me.first.isAdmin;
  }

  void _showInviteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _InviteMembersSheet(
        roomId: widget.roomId,
        existingMemberIds: ref
            .read(chatMembersProvider(widget.roomId))
            .members
            .map((m) => m.userId)
            .toSet(),
      ),
    );
  }

  void _confirmKick(ChatMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('멤버 내보내기'),
        content: Text('${member.nickname} 님을 채팅방에서 내보내시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(chatMembersProvider(widget.roomId).notifier)
                  .kickMember(member.userId);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('이 그룹 채팅방에서 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(chatMembersProvider(widget.roomId).notifier)
                  .leaveRoom();
              if (success && mounted) {
                ref.read(chatRoomsProvider.notifier).loadRooms();
                context.go('/chats');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(chatMembersProvider(widget.roomId));
    final roomState = ref.watch(chatRoomsProvider);
    final room = roomState.rooms.where((r) => r.id == widget.roomId).toList();
    final roomData = room.isNotEmpty ? room.first : null;
    final isAdmin = _isCurrentUserAdmin(membersState.members);

    ref.listen<ChatMembersState>(chatMembersProvider(widget.roomId),
        (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref
            .read(chatMembersProvider(widget.roomId).notifier)
            .clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('멤버 (${membersState.members.length}명)'),
      ),
      body: membersState.isLoading && membersState.members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Group info header
                if (roomData != null) _buildGroupHeader(roomData),

                const Divider(height: 1),

                // Invite button (admin only)
                if (isAdmin)
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_outlined,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      '멤버 초대',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: _showInviteDialog,
                  ),

                // Members list
                Expanded(
                  child: ListView.builder(
                    itemCount: membersState.members.length,
                    itemBuilder: (context, index) {
                      final member = membersState.members[index];
                      final isMe = member.userId == _currentUserId;
                      return _MemberTile(
                        member: member,
                        isMe: isMe,
                        showKick: isAdmin && !isMe && !member.isOwner,
                        onKick: () => _confirmKick(member),
                      );
                    },
                  ),
                ),

                // Leave button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _confirmLeave,
                        icon: const Icon(Icons.exit_to_app, size: 20),
                        label: const Text('채팅방 나가기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupHeader(ChatRoomModel room) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _GroupAvatarLarge(room: room),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name.isNotEmpty ? room.name : '그룹 채팅',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${room.memberCount}명 참여중',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupAvatarLarge extends StatelessWidget {
  final ChatRoomModel room;

  const _GroupAvatarLarge({required this.room});

  @override
  Widget build(BuildContext context) {
    if (room.imageUrl != null && room.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(room.imageUrl!),
        backgroundColor: AppTheme.surfaceLight,
      );
    }

    return CircleAvatar(
      radius: 32,
      backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.3),
      child: const Icon(
        Icons.group,
        size: 30,
        color: AppTheme.primaryDark,
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ChatMember member;
  final bool isMe;
  final bool showKick;
  final VoidCallback? onKick;

  const _MemberTile({
    required this.member,
    required this.isMe,
    this.showKick = false,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: AvatarWidget(
        name: member.nickname,
        imageUrl: member.profileImageUrl,
        radius: 22,
        showOnlineIndicator: true,
        isOnline: member.isOnline,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '나',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (member.isOwner) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '방장',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        member.isOnline ? '온라인' : '오프라인',
        style: TextStyle(
          fontSize: 13,
          color: member.isOnline
              ? AppTheme.onlineGreen
              : const Color(0xFFC7C7CC),
        ),
      ),
      trailing: showKick
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: const Color(0xFF8E8E93),
              onPressed: onKick,
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Invite Members Bottom Sheet
// ═══════════════════════════════════════════════════════════════

class _InviteMembersSheet extends ConsumerStatefulWidget {
  final int roomId;
  final Set<int> existingMemberIds;

  const _InviteMembersSheet({
    required this.roomId,
    required this.existingMemberIds,
  });

  @override
  ConsumerState<_InviteMembersSheet> createState() =>
      _InviteMembersSheetState();
}

class _InviteMembersSheetState extends ConsumerState<_InviteMembersSheet> {
  final Set<int> _selectedIds = {};
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(friendsProvider.notifier).loadFriends();
    });
  }

  List<FriendModel> get _availableFriends {
    return ref
        .watch(friendsProvider)
        .friends
        .where((f) => !widget.existingMemberIds.contains(f.id))
        .toList();
  }

  Future<void> _invite() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isInviting = true);
    final success = await ref
        .read(chatMembersProvider(widget.roomId).notifier)
        .inviteMembers(_selectedIds.toList());
    if (mounted) {
      Navigator.of(context).pop();
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('멤버 초대에 실패했습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = _availableFriends;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '멤버 초대',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _selectedIds.isNotEmpty && !_isInviting
                        ? _invite
                        : null,
                    child: _isInviting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('초대 (${_selectedIds.length})'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Friends list
            Expanded(
              child: friends.isEmpty
                  ? const Center(
                      child: Text(
                        '초대할 수 있는 친구가 없습니다',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final isSelected = _selectedIds.contains(friend.id);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 2),
                          leading: AvatarWidget(
                            name: friend.nickname,
                            imageUrl: friend.profileImageUrl,
                            radius: 22,
                          ),
                          title: Text(
                            friend.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFFC7C7CC),
                            size: 24,
                          ),
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
        );
      },
    );
  }
}
