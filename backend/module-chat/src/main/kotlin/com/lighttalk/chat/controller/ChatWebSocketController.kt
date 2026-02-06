package com.lighttalk.chat.controller

import com.lighttalk.chat.dto.ReadReceiptRequest
import com.lighttalk.chat.dto.SendMessageRequest
import com.lighttalk.chat.service.ChatNotificationService
import com.lighttalk.chat.service.MessageService
import org.slf4j.LoggerFactory
import org.springframework.messaging.handler.annotation.DestinationVariable
import org.springframework.messaging.handler.annotation.MessageMapping
import org.springframework.messaging.handler.annotation.Payload
import org.springframework.stereotype.Controller
import java.security.Principal

@Controller
class ChatWebSocketController(
    private val messageService: MessageService,
    private val chatNotificationService: ChatNotificationService
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @MessageMapping("/chat/{roomId}/send")
    fun sendMessage(
        @DestinationVariable roomId: Long,
        @Payload request: SendMessageRequest,
        principal: Principal
    ) {
        val senderId = principal.name.toLong()
        log.debug("WebSocket message received: roomId={}, senderId={}", roomId, senderId)

        val messageResponse = messageService.sendMessage(roomId, senderId, request)
        chatNotificationService.notifyNewMessage(messageResponse)
    }

    @MessageMapping("/chat/{roomId}/read")
    fun markAsRead(
        @DestinationVariable roomId: Long,
        @Payload request: ReadReceiptRequest,
        principal: Principal
    ) {
        val userId = principal.name.toLong()
        log.debug("WebSocket read receipt: roomId={}, userId={}, messageId={}", roomId, userId, request.messageId)

        messageService.markAsRead(roomId, userId, request.messageId)
        chatNotificationService.notifyReadReceipt(roomId, userId, request.messageId)
    }
}
