package com.lighttalk.app.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Positive

data class PresignRequest(
    @field:NotBlank(message = "파일 이름은 필수입니다")
    val fileName: String,

    @field:NotBlank(message = "Content-Type은 필수입니다")
    val contentType: String,

    @field:Positive(message = "파일 크기는 0보다 커야 합니다")
    val contentLength: Long,

    val purpose: UploadPurpose,

    val chatRoomId: Long? = null
)

enum class UploadPurpose {
    PROFILE,
    CHAT_IMAGE,
    CHAT_VIDEO
}
