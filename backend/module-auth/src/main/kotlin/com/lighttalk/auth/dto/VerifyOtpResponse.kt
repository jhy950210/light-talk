package com.lighttalk.auth.dto

data class VerifyOtpResponse(
    val verificationToken: String,
    val isNewUser: Boolean
)
