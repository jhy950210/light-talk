package com.lighttalk.chat.dto

import com.lighttalk.core.entity.ChatRoomType
import jakarta.validation.constraints.NotNull

data class CreateChatRoomRequest(
    @field:NotNull(message = "대상 사용자 ID는 필수입니다")
    val targetUserId: Long
)

data class CreateGroupChatRequest(
    @field:NotNull(message = "그룹 채팅방 이름은 필수입니다")
    val name: String,

    @field:NotNull(message = "초대할 멤버 목록은 필수입니다")
    val memberIds: List<Long>,

    val imageUrl: String? = null
)

data class UpdateChatRoomRequest(
    val name: String? = null,
    val imageUrl: String? = null
)

data class InviteMembersRequest(
    @field:NotNull(message = "초대할 멤버 목록은 필수입니다")
    val userIds: List<Long>
)

data class UpdateMemberRoleRequest(
    @field:NotNull(message = "역할은 필수입니다")
    val role: String
)
