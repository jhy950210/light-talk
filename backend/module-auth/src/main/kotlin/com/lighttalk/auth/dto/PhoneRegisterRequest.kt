package com.lighttalk.auth.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size

data class PhoneRegisterRequest(
    @field:NotBlank(message = "인증 토큰은 필수입니다")
    val verificationToken: String,

    @field:NotBlank(message = "비밀번호는 필수입니다")
    @field:Size(min = 6, message = "비밀번호는 최소 6자 이상이어야 합니다")
    @field:Pattern(regexp = ".*[a-z].*", message = "비밀번호에 소문자를 포함해야 합니다")
    val password: String,

    @field:NotBlank(message = "닉네임은 필수입니다")
    @field:Size(max = 20, message = "닉네임은 최대 20자까지 가능합니다")
    val nickname: String
)
