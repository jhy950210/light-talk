package com.lighttalk.user.dto

data class FriendResponse(
    val id: Long,
    val nickname: String,
    val tag: String,
    val profileImageUrl: String?,
    val isOnline: Boolean,
    val friendshipId: Long? = null
)
