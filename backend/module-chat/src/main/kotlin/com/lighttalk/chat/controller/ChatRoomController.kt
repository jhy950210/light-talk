package com.lighttalk.chat.controller

import com.lighttalk.chat.dto.ChatRoomResponse
import com.lighttalk.chat.dto.CreateChatRoomRequest
import com.lighttalk.chat.dto.CreateGroupChatRequest
import com.lighttalk.chat.dto.InviteMembersRequest
import com.lighttalk.chat.dto.UpdateChatRoomRequest
import com.lighttalk.chat.dto.UpdateMemberRoleRequest
import com.lighttalk.chat.service.ChatRoomService
import com.lighttalk.core.dto.ApiResponse
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.security.Principal

@RestController
@RequestMapping("/api/v1/chats")
class ChatRoomController(
    private val chatRoomService: ChatRoomService
) {

    @PostMapping
    fun createDirectChat(
        principal: Principal,
        @Valid @RequestBody request: CreateChatRoomRequest
    ): ResponseEntity<ApiResponse<ChatRoomResponse>> {
        val userId = principal.name.toLong()
        val response = chatRoomService.createDirectChat(userId, request.targetUserId)
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(response))
    }

    @PostMapping("/group")
    fun createGroupChat(
        principal: Principal,
        @Valid @RequestBody request: CreateGroupChatRequest
    ): ResponseEntity<ApiResponse<ChatRoomResponse>> {
        val userId = principal.name.toLong()
        val response = chatRoomService.createGroupChat(userId, request.name, request.memberIds, request.imageUrl)
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(response))
    }

    @GetMapping
    fun getMyChatRooms(
        principal: Principal
    ): ResponseEntity<ApiResponse<List<ChatRoomResponse>>> {
        val userId = principal.name.toLong()
        val response = chatRoomService.getMyChatRooms(userId)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @GetMapping("/{roomId}")
    fun getChatRoom(
        principal: Principal,
        @PathVariable roomId: Long
    ): ResponseEntity<ApiResponse<ChatRoomResponse>> {
        val userId = principal.name.toLong()
        val response = chatRoomService.getChatRoom(roomId, userId)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PutMapping("/{roomId}")
    fun updateRoom(
        principal: Principal,
        @PathVariable roomId: Long,
        @Valid @RequestBody request: UpdateChatRoomRequest
    ): ResponseEntity<ApiResponse<ChatRoomResponse>> {
        val userId = principal.name.toLong()
        val response = chatRoomService.updateRoom(roomId, userId, request.name, request.imageUrl)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PostMapping("/{roomId}/members")
    fun inviteMembers(
        principal: Principal,
        @PathVariable roomId: Long,
        @Valid @RequestBody request: InviteMembersRequest
    ): ResponseEntity<ApiResponse<ChatRoomResponse>> {
        val userId = principal.name.toLong()
        val response = chatRoomService.inviteMembers(roomId, userId, request.userIds)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @DeleteMapping("/{roomId}/members/{targetUserId}")
    fun removeMember(
        principal: Principal,
        @PathVariable roomId: Long,
        @PathVariable targetUserId: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        val userId = principal.name.toLong()
        chatRoomService.removeMember(roomId, userId, targetUserId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    @PostMapping("/{roomId}/leave")
    fun leaveRoom(
        principal: Principal,
        @PathVariable roomId: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        val userId = principal.name.toLong()
        chatRoomService.leaveRoom(roomId, userId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    @PutMapping("/{roomId}/members/{targetUserId}/role")
    fun changeMemberRole(
        principal: Principal,
        @PathVariable roomId: Long,
        @PathVariable targetUserId: Long,
        @Valid @RequestBody request: UpdateMemberRoleRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        val userId = principal.name.toLong()
        chatRoomService.changeRole(roomId, userId, targetUserId, request.role)
        return ResponseEntity.ok(ApiResponse.success())
    }
}
