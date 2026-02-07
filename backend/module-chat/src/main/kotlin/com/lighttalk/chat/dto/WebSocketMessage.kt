package com.lighttalk.chat.dto

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
