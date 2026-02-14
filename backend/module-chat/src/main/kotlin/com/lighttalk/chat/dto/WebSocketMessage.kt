package com.lighttalk.chat.dto

import com.lighttalk.core.entity.ChatMemberRole
import java.time.LocalDateTime

/**
 * WebSocket event types sent over STOMP.
 */
data class ChatMessageEvent(
    val type: String = "NEW_MESSAGE",
    val message: MessageResponse
)

data class ReadReceiptEvent(
    val type: String = "READ_RECEIPT",
    val chatRoomId: Long,
    val userId: Long,
    val messageId: Long,
    val readAt: LocalDateTime = LocalDateTime.now()
)

data class UserStatusEvent(
    val type: String,
    val userId: Long,
    val online: Boolean
)

data class MessageDeletedEvent(
    val type: String = "MESSAGE_DELETED",
    val chatRoomId: Long,
    val messageId: Long
)

data class MemberJoinedEvent(
    val type: String = "MEMBER_JOINED",
    val chatRoomId: Long,
    val members: List<ChatMemberInfo>
)

data class MemberLeftEvent(
    val type: String = "MEMBER_LEFT",
    val chatRoomId: Long,
    val userId: Long,
    val newOwnerId: Long? = null
)

data class ChatRoomUpdatedEvent(
    val type: String = "CHAT_ROOM_UPDATED",
    val chatRoomId: Long,
    val name: String?,
    val imageUrl: String?
)

data class RoleChangedEvent(
    val type: String = "ROLE_CHANGED",
    val chatRoomId: Long,
    val userId: Long,
    val newRole: ChatMemberRole
)
