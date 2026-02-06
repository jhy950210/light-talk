package com.lighttalk.chat.dto

import jakarta.validation.constraints.NotNull

data class ReadReceiptRequest(
    @field:NotNull(message = "메시지 ID는 필수입니다")
    val messageId: Long
)
