package com.lighttalk.user.dto

import jakarta.validation.constraints.NotBlank

data class WithdrawalRequest(
    @field:NotBlank(message = "비밀번호를 입력해주세요")
    val password: String
)
