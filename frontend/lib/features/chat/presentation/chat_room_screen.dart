import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/providers.dart';
import '../data/models/message_model.dart';
import '../providers/chat_provider.dart';
import 'widgets/image_bubble.dart';
import 'widgets/video_bubble.dart';

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
  final _imagePicker = ImagePicker();
  bool _showScrollToBottom = false;

  int get _currentUserId =>
      ref.read(sharedPreferencesProvider).getInt(ApiConstants.userIdKey) ?? 0;

  String get _currentNickname =>
      ref.read(sharedPreferencesProvider)
          .getString(ApiConstants.userNicknameKey) ??
      '';

  int _lastReadMessageCount = 0;
  int? _lastSeenMessageId;
  ProviderSubscription? _messagesSub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(activeChatRoomProvider.notifier).state = widget.roomId;
      final notifier = ref.read(messagesProvider(widget.roomId).notifier);
      notifier.subscribeToRoom();
      notifier.loadMessages().then((_) {
        final msgs = ref.read(messagesProvider(widget.roomId)).messages;
        if (msgs.isNotEmpty) _lastSeenMessageId = msgs.first.id;
        notifier.markAsRead();
      });
      // Listen for new messages to mark them as read while screen is visible
      _messagesSub = ref.listenManual(messagesProvider(widget.roomId), (prev, next) {
        if (next.messages.length > _lastReadMessageCount && _lastReadMessageCount > 0) {
          if (next.messages.isNotEmpty) _lastSeenMessageId = next.messages.first.id;
          ref.read(messagesProvider(widget.roomId).notifier).markAsRead();
        }
        _lastReadMessageCount = next.messages.length;
      });
    });
  }

  @override
  void dispose() {
    // Cancel message listener FIRST to prevent further markAsRead calls
    _messagesSub?.close();
    _messagesSub = null;
    // Clear active room tracking
    ref.read(activeChatRoomProvider.notifier).state = null;
    // Capture references before super.dispose()
    final msgNotifier = ref.read(messagesProvider(widget.roomId).notifier);
    final roomsNotifier = ref.read(chatRoomsProvider.notifier);
    final savedMessageId = _lastSeenMessageId;
    msgNotifier.unsubscribeFromRoom();
    // Use saved message ID (not state.messages.first.id) to avoid marking
    // messages that arrived after user started navigating away.
    if (savedMessageId != null) {
      msgNotifier.markAsRead(messageId: savedMessageId).then((_) {
        roomsNotifier.loadRooms();
      }).catchError((_) {});
    } else {
      roomsNotifier.loadRooms();
    }
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

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 사진 선택'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('카메라로 사진 촬영'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('갤러리에서 동영상 선택'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('카메라로 동영상 촬영'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickVideo(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;

    // Compress image
    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      '${picked.path}_compressed.jpg',
      quality: 80,
      minWidth: 1920,
      minHeight: 1920,
    );

    final file = File(compressed?.path ?? picked.path);
    final contentType = lookupMimeType(file.path) ?? 'image/jpeg';

    ref.read(messagesProvider(widget.roomId).notifier).sendMediaMessage(
      file: file,
      contentType: contentType,
      messageType: 'IMAGE',
      senderId: _currentUserId,
      senderNickname: _currentNickname,
    );
    _scrollToBottom();
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _imagePicker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 3),
    );
    if (picked == null) return;

    final file = File(picked.path);
    final fileSize = await file.length();

    // Check file size (50MB limit)
    if (fileSize > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('동영상은 50MB 이하만 전송할 수 있습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final contentType = lookupMimeType(file.path) ?? 'video/mp4';

    ref.read(messagesProvider(widget.roomId).notifier).sendMediaMessage(
      file: file,
      contentType: contentType,
      messageType: 'VIDEO',
      senderId: _currentUserId,
      senderNickname: _currentNickname,
    );
    _scrollToBottom();
  }

  void _showDeleteMenu(MessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  '메시지 삭제',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(message);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 모든 사용자에게서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(messagesProvider(widget.roomId).notifier)
                  .deleteMessage(message.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msgState = ref.watch(messagesProvider(widget.roomId));
    final roomState = ref.watch(chatRoomsProvider);

    // Find room from rooms list
    final rooms = roomState.rooms
        .where((r) => r.id == widget.roomId)
        .toList();
    final roomData = rooms.isNotEmpty ? rooms.first : null;
    final isGroup = roomData?.isGroup ?? false;
    final roomName = roomData != null
        ? (roomData.name.isNotEmpty ? roomData.name : '채팅')
        : '채팅';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              roomName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (roomData != null && roomData.members.isNotEmpty)
              Text(
                isGroup
                    ? '${roomData.memberCount}명 참여중'
                    : roomData.members.any((m) => m.isOnline)
                        ? '온라인'
                        : '오프라인',
                style: TextStyle(
                  fontSize: 12,
                  color: isGroup
                      ? AppTheme.textSecondary
                      : roomData.members.any((m) => m.isOnline)
                          ? AppTheme.onlineGreen
                          : AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: '멤버 관리',
              onPressed: () =>
                  context.push('/chats/${widget.roomId}/members'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Upload progress ─────────────────────────
          if (msgState.isUploading)
            LinearProgressIndicator(
              value: msgState.uploadProgress > 0 ? msgState.uploadProgress : null,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),

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
          _buildInputBar(context, msgState),
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
              '첫 메시지를 보내보세요!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
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
            GestureDetector(
              onLongPress: !message.isDeleted &&
                      message.canBeDeletedBy(_currentUserId)
                  ? () => _showDeleteMenu(message)
                  : null,
              child: _MessageBubble(
                message: message,
                isMine: isMine,
                showAvatar: showAvatar,
                showSenderName: showAvatar,
              ),
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
      label = '오늘';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = '어제';
    } else {
      label = DateFormat('yyyy년 M월 d일').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.borderColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, MessagesState msgState) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
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
          // (+) Media button
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: msgState.isUploading ? null : _showMediaPicker,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add_circle_outline,
                  color: msgState.isUploading
                      ? AppTheme.borderColor
                      : AppTheme.primaryColor,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
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
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
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
                  : AppTheme.borderColor,
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
                        : AppTheme.textSecondary,
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

    if (message.isDeleted) {
      return _buildDeletedMessage(context, timeStr);
    }

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.7;

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
          // Read status + Time (for sent messages, show on left of bubble)
          if (isMine)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isRead)
                    const Text(
                      '읽음',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
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
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                if (message.isImage)
                  ImageBubble(
                    imageUrl: message.mediaUrl,
                    isMine: isMine,
                    maxWidth: maxBubbleWidth,
                  )
                else if (message.isVideo)
                  VideoBubble(
                    videoUrl: message.mediaUrl,
                    isMine: isMine,
                    maxWidth: maxBubbleWidth,
                  )
                else
                  Container(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                        color:
                            isMine ? Colors.white : AppTheme.textPrimary,
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
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeletedMessage(BuildContext context, String timeStr) {
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
          if (isMine)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 0.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '삭제된 메시지입니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
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
            color: AppTheme.borderColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
