package com.lighttalk.chat.dto

data class MessagePageResponse(
    val messages: List<MessageResponse>,
    val hasMore: Boolean,
    val nextCursor: Long?
)
