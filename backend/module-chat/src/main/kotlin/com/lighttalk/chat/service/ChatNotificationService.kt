package com.lighttalk.chat.service

import com.lighttalk.chat.dto.ChatMessageEvent
import com.lighttalk.chat.dto.MessageDeletedEvent
import com.lighttalk.chat.dto.MessageResponse
import com.lighttalk.chat.dto.ReadReceiptEvent
import com.lighttalk.chat.repository.ChatMemberRepository
import org.slf4j.LoggerFactory
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service

@Service
class ChatNotificationService(
    private val messagingTemplate: SimpMessagingTemplate,
    private val chatMemberRepository: ChatMemberRepository
) {

    private val log = LoggerFactory.getLogger(javaClass)

    fun notifyNewMessage(message: MessageResponse) {
        val event = ChatMessageEvent(message = message)

        // Broadcast to chat room topic
        val destination = "/topic/chat/${message.chatRoomId}"
        messagingTemplate.convertAndSend(destination, event)
        log.debug("Message broadcast to {}: messageId={}", destination, message.id)

        // Also send to individual user queues for members not actively subscribed
        val members = chatMemberRepository.findByChatRoomId(message.chatRoomId)
        members.filter { it.userId != message.senderId }
            .forEach { member ->
                val userDestination = "/queue/user/${member.userId}"
                messagingTemplate.convertAndSend(userDestination, event)
                log.debug("Message sent to user queue: userId={}, messageId={}", member.userId, message.id)
            }
    }

    fun notifyMessageDeleted(chatRoomId: Long, messageId: Long) {
        val event = MessageDeletedEvent(
            chatRoomId = chatRoomId,
            messageId = messageId
        )

        val destination = "/topic/chat/$chatRoomId"
        messagingTemplate.convertAndSend(destination, event)
        log.debug("Message deleted event broadcast to {}: messageId={}", destination, messageId)

        // Also send to individual user queues
        val members = chatMemberRepository.findByChatRoomId(chatRoomId)
        members.forEach { member ->
            val userDestination = "/queue/user/${member.userId}"
            messagingTemplate.convertAndSend(userDestination, event)
        }
    }

    fun notifyReadReceipt(chatRoomId: Long, userId: Long, messageId: Long) {
        val event = ReadReceiptEvent(
            chatRoomId = chatRoomId,
            userId = userId,
            messageId = messageId
        )

        val destination = "/topic/chat/$chatRoomId"
        messagingTemplate.convertAndSend(destination, event)
        log.debug("Read receipt broadcast to {}: userId={}, messageId={}", destination, userId, messageId)
    }
}
