package com.lighttalk.user.dto

import jakarta.validation.constraints.Size

data class UpdateProfileRequest(
    @field:Size(max = 20, message = "닉네임은 최대 20자까지 가능합니다")
    val nickname: String?,

    val profileImageUrl: String?
)
