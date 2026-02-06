package com.lighttalk.user.dto

data class FriendResponse(
    val id: Long,
    val nickname: String,
    val profileImageUrl: String?,
    val isOnline: Boolean
)
