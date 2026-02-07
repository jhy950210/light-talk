package com.lighttalk.auth.dto

import jakarta.validation.constraints.NotBlank

data class PhoneLoginRequest(
    @field:NotBlank(message = "전화번호는 필수입니다")
    val phoneNumber: String,

    @field:NotBlank(message = "비밀번호는 필수입니다")
    val password: String
)
