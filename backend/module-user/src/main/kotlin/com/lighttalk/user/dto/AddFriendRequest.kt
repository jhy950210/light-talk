package com.lighttalk.user.dto

import jakarta.validation.constraints.Email

data class AddFriendRequest(
    @field:Email(message = "올바른 이메일 형식이 아닙니다")
    val friendEmail: String
)
