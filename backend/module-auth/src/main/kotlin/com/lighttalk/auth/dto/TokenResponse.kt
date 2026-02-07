package com.lighttalk.auth.dto

data class TokenResponse(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long,
    val userId: Long = 0,
    val nickname: String = "",
    val tag: String = ""
)
