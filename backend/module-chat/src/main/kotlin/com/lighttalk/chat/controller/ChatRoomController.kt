package com.lighttalk.chat.controller

import com.lighttalk.chat.dto.ChatRoomResponse
import com.lighttalk.chat.dto.CreateChatRoomRequest
import com.lighttalk.chat.service.ChatRoomService
import com.lighttalk.core.dto.ApiResponse
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
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
}
