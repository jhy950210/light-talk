package com.lighttalk.user.dto

data class UserResponse(
    val id: Long,
    val nickname: String,
    val tag: String,
    val profileImageUrl: String?,
    val isOnline: Boolean
)
