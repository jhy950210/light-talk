package com.lighttalk.auth.dto

import com.fasterxml.jackson.annotation.JsonProperty

data class VerifyOtpResponse(
    val verificationToken: String,
    @get:JsonProperty("isNewUser")
    val isNewUser: Boolean
)
