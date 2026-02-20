import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../data/models/chat_room_model.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatRoomsProvider.notifier).loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomsProvider);

    ref.listen<ChatRoomsState>(chatRoomsProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(chatRoomsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: '그룹 채팅 만들기',
            onPressed: () => context.push('/chats/new/group'),
          ),
        ],
      ),
      body: state.isLoading && state.rooms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.rooms.isEmpty
              ? _buildErrorState(context, state.errorMessage!)
              : state.rooms.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(chatRoomsProvider.notifier).loadRooms(),
                      child: _buildChatList(context, state),
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
                  ref.read(chatRoomsProvider.notifier).loadRooms(),
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
              Icons.chat_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 대화가 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '친구 목록에서 대화를 시작해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, ChatRoomsState state) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.rooms.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(left: 76),
        child: Divider(height: 1),
      ),
      itemBuilder: (context, index) {
        final room = state.rooms[index];
        return Dismissible(
          key: ValueKey(room.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: AppTheme.errorRed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.exit_to_app, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  room.isGroup ? '나가기' : '삭제',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            final title = room.isGroup ? '채팅방 나가기' : '대화 삭제';
            final message = room.isGroup
                ? '이 그룹 채팅방에서 나가시겠습니까?'
                : '이 대화를 삭제하시겠습니까?';
            return showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                    ),
                    child: Text(room.isGroup ? '나가기' : '삭제'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref.read(chatRoomsProvider.notifier).leaveRoom(room.id);
          },
          child: _ChatRoomTile(room: room),
        );
      },
    );
  }
}

class _ChatRoomTile extends ConsumerWidget {
  final ChatRoomModel room;

  const _ChatRoomTile({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        ref.read(sharedPreferencesProvider).getInt(ApiConstants.userIdKey) ?? 0;
    final hasUnread = room.unreadCount > 0;
    final lastMsg = room.lastMessage;
    final timeStr = lastMsg != null ? _formatTime(lastMsg.createdAt) : '';

    // Derive display name and avatar based on room type
    String displayName;
    String? displayImage;
    bool showOnlineIndicator;
    bool isOnline;

    if (room.isGroup) {
      displayName = room.name.isNotEmpty ? room.name : '그룹 채팅';
      displayImage = room.imageUrl;
      showOnlineIndicator = false;
      isOnline = false;
    } else {
      final otherMember = room.members.cast<ChatMember?>().firstWhere(
            (m) => m!.userId != currentUserId,
            orElse: () => room.members.isNotEmpty ? room.members.first : null,
          );
      displayName =
          room.name.isNotEmpty ? room.name : (otherMember?.nickname ?? '채팅');
      displayImage = room.imageUrl ?? otherMember?.profileImageUrl;
      showOnlineIndicator = otherMember != null;
      isOnline = otherMember?.isOnline ?? false;
    }

    return InkWell(
      onTap: () => context.push('/chats/${room.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ───────────────────────────────
            if (room.isGroup && displayImage == null)
              _GroupAvatar(room: room, radius: 26)
            else
              AvatarWidget(
                name: displayName,
                imageUrl: displayImage,
                radius: 26,
                showOnlineIndicator: showOnlineIndicator,
                isOnline: isOnline,
              ),
            const SizedBox(width: 14),

            // ── Content ──────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room name + member count (group) + time
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (room.isGroup) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${room.memberCount}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last message + unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg != null
                              ? '${lastMsg.senderNickname}: ${_lastMessagePreview(lastMsg)}'
                              : '메시지 없음',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? AppTheme.textBody
                                : AppTheme.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.unreadBadge,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 20),
                          child: Text(
                            room.unreadCount > 99
                                ? '99+'
                                : room.unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastMessagePreview(LastMessage lastMsg) {
    switch (lastMsg.type) {
      case 'IMAGE':
        return '사진';
      case 'VIDEO':
        return '동영상';
      default:
        return lastMsg.content;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat.Hm().format(dateTime);
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }
}

/// Group avatar: shows a group icon with member count overlay
class _GroupAvatar extends StatelessWidget {
  final ChatRoomModel room;
  final double radius;

  const _GroupAvatar({required this.room, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.3),
      child: Icon(
        Icons.group,
        size: radius * 0.9,
        color: AppTheme.primaryDark,
      ),
    );
  }
}
