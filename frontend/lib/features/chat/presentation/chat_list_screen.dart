import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        title: const Text('Chats'),
      ),
      body: state.isLoading && state.rooms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.rooms.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(chatRoomsProvider.notifier).loadRooms(),
                  child: _buildChatList(context, state),
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
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a chat from your friends list',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC7C7CC),
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
        return _ChatRoomTile(room: room);
      },
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomModel room;

  const _ChatRoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final hasUnread = room.unreadCount > 0;
    final lastMsg = room.lastMessage;
    final timeStr = lastMsg != null ? _formatTime(lastMsg.createdAt) : '';

    return InkWell(
      onTap: () => context.push('/chats/${room.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ───────────────────────────────
            AvatarWidget(
              name: room.name,
              imageUrl: room.imageUrl,
              radius: 26,
              showOnlineIndicator: room.members.isNotEmpty,
              isOnline:
                  room.members.any((m) => m.isOnline),
            ),
            const SizedBox(width: 14),

            // ── Content ──────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room name + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? AppTheme.primaryColor
                                : const Color(0xFF8E8E93),
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
                              : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? const Color(0xFF3C3C43)
                                : const Color(0xFF8E8E93),
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
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }
}
