package com.lighttalk.user.dto

data class UserResponse(
    val id: Long,
    val email: String,
    val nickname: String,
    val profileImageUrl: String?,
    val isOnline: Boolean
)
