package com.lighttalk.app.controller

import com.lighttalk.app.dto.PresignRequest
import com.lighttalk.app.dto.UploadPurpose
import com.lighttalk.chat.repository.ChatMemberRepository
import com.lighttalk.core.dto.ApiResponse
import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import com.lighttalk.core.storage.FileStorageService
import com.lighttalk.core.storage.PresignedUrlResponse
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/api/v1/upload")
class UploadController(
    private val fileStorageService: FileStorageService,
    private val chatMemberRepository: ChatMemberRepository
) {

    companion object {
        private val ALLOWED_IMAGE_TYPES = setOf(
            "image/jpeg", "image/png", "image/webp", "image/gif"
        )
        private val ALLOWED_VIDEO_TYPES = setOf(
            "video/mp4", "video/quicktime", "video/webm"
        )
        private const val MAX_IMAGE_SIZE = 10L * 1024 * 1024      // 10 MB
        private const val MAX_VIDEO_SIZE = 50L * 1024 * 1024      // 50 MB
        private const val MAX_PROFILE_SIZE = 10L * 1024 * 1024    // 10 MB
    }

    @PostMapping("/presign")
    fun getPresignedUrl(
        @AuthenticationPrincipal userId: Long,
        @Valid @RequestBody request: PresignRequest
    ): ResponseEntity<ApiResponse<PresignedUrlResponse>> {
        validateRequest(request)
        validateChatMembership(userId, request)

        val path = generatePath(userId, request)
        val response = fileStorageService.generatePresignedUploadUrl(
            path = path,
            contentType = request.contentType,
            contentLength = request.contentLength
        )

        return ResponseEntity.ok(ApiResponse.success(response))
    }

    private fun validateRequest(request: PresignRequest) {
        when (request.purpose) {
            UploadPurpose.PROFILE -> {
                if (request.contentType !in ALLOWED_IMAGE_TYPES) {
                    throw ApiException(ErrorCode.INVALID_FILE_TYPE, "프로필 사진은 JPEG, PNG, WebP, GIF만 허용됩니다")
                }
                if (request.contentLength > MAX_PROFILE_SIZE) {
                    throw ApiException(ErrorCode.FILE_TOO_LARGE, "프로필 사진은 10MB 이하만 허용됩니다")
                }
            }
            UploadPurpose.CHAT_IMAGE -> {
                if (request.contentType !in ALLOWED_IMAGE_TYPES) {
                    throw ApiException(ErrorCode.INVALID_FILE_TYPE, "이미지는 JPEG, PNG, WebP, GIF만 허용됩니다")
                }
                if (request.contentLength > MAX_IMAGE_SIZE) {
                    throw ApiException(ErrorCode.FILE_TOO_LARGE, "이미지는 10MB 이하만 허용됩니다")
                }
            }
            UploadPurpose.CHAT_VIDEO -> {
                if (request.contentType !in ALLOWED_VIDEO_TYPES) {
                    throw ApiException(ErrorCode.INVALID_FILE_TYPE, "동영상은 MP4, MOV, WebM만 허용됩니다")
                }
                if (request.contentLength > MAX_VIDEO_SIZE) {
                    throw ApiException(ErrorCode.FILE_TOO_LARGE, "동영상은 50MB 이하만 허용됩니다")
                }
            }
        }
    }

    private fun validateChatMembership(userId: Long, request: PresignRequest) {
        if (request.purpose == UploadPurpose.CHAT_IMAGE || request.purpose == UploadPurpose.CHAT_VIDEO) {
            val roomId = request.chatRoomId ?: return
            chatMemberRepository.findActiveByChatRoomIdAndUserId(roomId, userId)
                ?: throw ApiException(ErrorCode.NOT_CHAT_MEMBER)
        }
    }

    private fun generatePath(userId: Long, request: PresignRequest): String {
        val extension = request.fileName.substringAfterLast('.', "")
        val uuid = UUID.randomUUID()
        val fileName = if (extension.isNotEmpty()) "$uuid.$extension" else "$uuid"

        return when (request.purpose) {
            UploadPurpose.PROFILE -> "profiles/$userId/$fileName"
            UploadPurpose.CHAT_IMAGE, UploadPurpose.CHAT_VIDEO -> {
                val roomId = request.chatRoomId ?: throw ApiException(
                    ErrorCode.INVALID_INPUT_VALUE, "채팅 미디어 업로드 시 chatRoomId는 필수입니다"
                )
                "chats/$roomId/$fileName"
            }
        }
    }
}
