package com.lighttalk.chat.controller

import com.lighttalk.chat.dto.MessagePageResponse
import com.lighttalk.chat.dto.ReadReceiptRequest
import com.lighttalk.chat.service.ChatNotificationService
import com.lighttalk.chat.service.MessageService
import com.lighttalk.core.dto.ApiResponse
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.security.Principal

@RestController
@RequestMapping("/api/v1/chats")
class MessageController(
    private val messageService: MessageService,
    private val chatNotificationService: ChatNotificationService
) {

    @GetMapping("/{roomId}/messages")
    fun getMessages(
        principal: Principal,
        @PathVariable roomId: Long,
        @RequestParam(required = false) cursor: Long?,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<ApiResponse<MessagePageResponse>> {
        val userId = principal.name.toLong()
        val response = messageService.getMessages(roomId, userId, cursor, size)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PutMapping("/{roomId}/read")
    fun markAsRead(
        principal: Principal,
        @PathVariable roomId: Long,
        @Valid @RequestBody request: ReadReceiptRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        val userId = principal.name.toLong()
        messageService.markAsRead(roomId, userId, request.messageId)
        chatNotificationService.notifyReadReceipt(roomId, userId, request.messageId)
        return ResponseEntity.ok(ApiResponse.success())
    }
}
