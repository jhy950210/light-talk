package com.lighttalk.user.dto

import jakarta.validation.constraints.NotNull

data class AddFriendRequest(
    @field:NotNull(message = "친구 ID는 필수입니다")
    val friendId: Long
)
