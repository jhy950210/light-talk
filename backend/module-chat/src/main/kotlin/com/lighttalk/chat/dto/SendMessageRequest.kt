package com.lighttalk.chat.dto

import com.lighttalk.core.entity.MessageType
import jakarta.validation.constraints.NotBlank

data class SendMessageRequest(
    @field:NotBlank(message = "메시지 내용은 필수입니다")
    val content: String,
    val type: MessageType = MessageType.TEXT
)
