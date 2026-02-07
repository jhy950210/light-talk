import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/providers.dart';
import '../data/models/message_model.dart';
import '../providers/chat_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final int roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showScrollToBottom = false;

  int get _currentUserId =>
      ref.read(sharedPreferencesProvider).getInt(ApiConstants.userIdKey) ?? 0;

  String get _currentNickname =>
      ref.read(sharedPreferencesProvider)
          .getString(ApiConstants.userNicknameKey) ??
      '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      final notifier = ref.read(messagesProvider(widget.roomId).notifier);
      notifier.loadMessages();
      notifier.subscribeToRoom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show scroll-to-bottom button when scrolled up
    final showBtn = _scrollController.offset > 200;
    if (showBtn != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showBtn);
    }

    // Load more when approaching the top (end of reversed list)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(messagesProvider(widget.roomId).notifier).loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(messagesProvider(widget.roomId).notifier).sendMessage(
          text,
          _currentUserId,
          _currentNickname,
        );

    _messageController.clear();
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final msgState = ref.watch(messagesProvider(widget.roomId));
    final roomState = ref.watch(chatRoomsProvider);

    // Find room name from rooms list
    final room = roomState.rooms
        .where((r) => r.id == widget.roomId)
        .toList();
    final roomName =
        room.isNotEmpty ? room.first.name : 'Chat';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            ref
                .read(messagesProvider(widget.roomId).notifier)
                .unsubscribeFromRoom();
            ref
                .read(messagesProvider(widget.roomId).notifier)
                .markAsRead();
            context.pop();
          },
        ),
        title: Column(
          children: [
            Text(
              roomName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (room.isNotEmpty && room.first.members.isNotEmpty)
              Text(
                room.first.members.any((m) => m.isOnline)
                    ? 'Online'
                    : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: room.first.members.any((m) => m.isOnline)
                      ? AppTheme.onlineGreen
                      : const Color(0xFF8E8E93),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────
          Expanded(
            child: msgState.isLoading && msgState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      _buildMessageList(context, msgState),
                      if (_showScrollToBottom)
                        Positioned(
                          right: 16,
                          bottom: 8,
                          child: FloatingActionButton.small(
                            onPressed: _scrollToBottom,
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            elevation: 3,
                            child: const Icon(
                                Icons.keyboard_arrow_down_rounded),
                          ),
                        ),
                    ],
                  ),
          ),

          // ── Input Bar ─────────────────────────────
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, MessagesState state) {
    if (state.messages.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Say hello!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF8E8E93),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (state.isLoadingMore && index == state.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final message = state.messages[index];
        final isMine = message.isSentBy(_currentUserId);

        // Check if we should show date separator
        final showDateSep = _shouldShowDateSeparator(state.messages, index);

        // Check if we should show sender avatar (group sequential messages)
        final showAvatar = !isMine && _shouldShowAvatar(state.messages, index);

        return Column(
          children: [
            if (showDateSep)
              _buildDateSeparator(context, message.createdAt),
            _MessageBubble(
              message: message,
              isMine: isMine,
              showAvatar: showAvatar,
              showSenderName: showAvatar,
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    final current = messages[index].createdAt;
    final next = messages[index + 1].createdAt;
    return current.day != next.day ||
        current.month != next.month ||
        current.year != next.year;
  }

  bool _shouldShowAvatar(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    return messages[index].senderId != messages[index + 1].senderId;
  }

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5EA).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _messageController.text.trim().isNotEmpty
                  ? AppTheme.primaryColor
                  : const Color(0xFFE5E5EA),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _messageController.text.trim().isNotEmpty
                    ? _sendMessage
                    : null,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: _messageController.text.trim().isNotEmpty
                        ? Colors.white
                        : const Color(0xFF8E8E93),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Message Bubble Widget
// ═══════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showAvatar;
  final bool showSenderName;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.showAvatar = true,
    this.showSenderName = true,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.Hm().format(message.createdAt);

    if (message.type == 'SYSTEM') {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 8 : 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (showAvatar)
              AvatarWidget(
                name: message.senderNickname,
                imageUrl: message.senderProfileImageUrl,
                radius: 16,
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          // Time (for sent messages, show on left of bubble)
          if (isMine)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFC7C7CC),
                ),
              ),
            ),
          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine && showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderNickname,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppTheme.sentBubble
                        : AppTheme.receivedBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? Colors.white : const Color(0xFF1C1C1E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Time (for received messages, show on right of bubble)
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFC7C7CC),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5EA).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}
