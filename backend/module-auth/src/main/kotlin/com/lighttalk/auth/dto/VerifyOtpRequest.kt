package com.lighttalk.auth.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class VerifyOtpRequest(
    @field:NotBlank(message = "전화번호는 필수입니다")
    val phoneNumber: String,

    @field:NotBlank(message = "인증번호는 필수입니다")
    @field:Size(min = 6, max = 6, message = "인증번호는 6자리입니다")
    val code: String
)
