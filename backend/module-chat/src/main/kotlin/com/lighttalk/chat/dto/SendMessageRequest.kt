package com.lighttalk.chat.dto

import com.lighttalk.core.entity.MessageType
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class SendMessageRequest(
    @field:NotBlank(message = "메시지 내용은 필수입니다")
    @field:Size(max = 5000, message = "메시지는 최대 5000자까지 가능합니다")
    val content: String,
    val type: MessageType = MessageType.TEXT
)
