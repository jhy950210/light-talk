package com.lighttalk.chat.dto

import jakarta.validation.constraints.NotNull

data class CreateChatRoomRequest(
    @field:NotNull(message = "대상 사용자 ID는 필수입니다")
    val targetUserId: Long
)
