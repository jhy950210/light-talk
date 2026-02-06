package com.lighttalk.chat.dto

import com.lighttalk.core.entity.MessageType
import java.time.LocalDateTime

data class MessageResponse(
    val id: Long,
    val chatRoomId: Long,
    val senderId: Long,
    val senderNickname: String,
    val content: String,
    val type: MessageType,
    val createdAt: LocalDateTime,
    val isRead: Boolean
)
