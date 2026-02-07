package com.lighttalk.chat.dto

import com.lighttalk.core.entity.ChatRoomType
import java.time.LocalDateTime

data class ChatRoomResponse(
    val id: Long,
    val type: ChatRoomType,
    val members: List<ChatMemberInfo>,
    val lastMessage: LastMessageInfo?,
    val unreadCount: Long
)

data class ChatMemberInfo(
    val userId: Long,
    val nickname: String,
    val profileImageUrl: String?,
    val joinedAt: LocalDateTime
)

data class LastMessageInfo(
    val id: Long,
    val content: String,
    val senderId: Long,
    val type: String,
    val createdAt: LocalDateTime
)
