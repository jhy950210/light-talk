package com.lighttalk.chat.service

import com.lighttalk.chat.dto.ChatMemberInfo
import com.lighttalk.chat.dto.ChatMessageEvent
import com.lighttalk.chat.dto.ChatRoomUpdatedEvent
import com.lighttalk.chat.dto.MemberJoinedEvent
import com.lighttalk.chat.dto.MemberLeftEvent
import com.lighttalk.chat.dto.MessageDeletedEvent
import com.lighttalk.chat.dto.MessageResponse
import com.lighttalk.chat.dto.ReadReceiptEvent
import com.lighttalk.chat.dto.RoleChangedEvent
import com.lighttalk.chat.repository.ChatMemberRepository
import com.lighttalk.core.entity.ChatMemberRole
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
        members.filter { it.isActive && it.userId != message.senderId }
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
        members.filter { it.isActive }.forEach { member ->
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

    fun notifyMemberJoined(chatRoomId: Long, newMembers: List<ChatMemberInfo>) {
        val event = MemberJoinedEvent(
            chatRoomId = chatRoomId,
            members = newMembers
        )

        val destination = "/topic/chat/$chatRoomId"
        messagingTemplate.convertAndSend(destination, event)
        log.debug("Member joined event broadcast to {}: newMembers={}", destination, newMembers.map { it.userId })

        // Send to individual user queues for all active members
        val members = chatMemberRepository.findByChatRoomId(chatRoomId)
        members.filter { it.isActive }.forEach { member ->
            val userDestination = "/queue/user/${member.userId}"
            messagingTemplate.convertAndSend(userDestination, event)
        }
    }

    fun notifyMemberLeft(chatRoomId: Long, userId: Long, newOwnerId: Long?) {
        val event = MemberLeftEvent(
            chatRoomId = chatRoomId,
            userId = userId,
            newOwnerId = newOwnerId
        )

        val destination = "/topic/chat/$chatRoomId"
        messagingTemplate.convertAndSend(destination, event)
        log.debug("Member left event broadcast to {}: userId={}, newOwnerId={}", destination, userId, newOwnerId)

        // Send to individual user queues for remaining active members
        val members = chatMemberRepository.findByChatRoomId(chatRoomId)
        members.filter { it.isActive }.forEach { member ->
            val userDestination = "/queue/user/${member.userId}"
            messagingTemplate.convertAndSend(userDestination, event)
        }
    }

    fun notifyChatRoomUpdated(chatRoomId: Long, name: String?, imageUrl: String?) {
        val event = ChatRoomUpdatedEvent(
            chatRoomId = chatRoomId,
            name = name,
            imageUrl = imageUrl
        )

        val destination = "/topic/chat/$chatRoomId"
        messagingTemplate.convertAndSend(destination, event)
        log.debug("Chat room updated event broadcast to {}: name={}", destination, name)

        // Send to individual user queues for all active members
        val members = chatMemberRepository.findByChatRoomId(chatRoomId)
        members.filter { it.isActive }.forEach { member ->
            val userDestination = "/queue/user/${member.userId}"
            messagingTemplate.convertAndSend(userDestination, event)
        }
    }

    fun notifyRoleChanged(chatRoomId: Long, userId: Long, newRole: ChatMemberRole) {
        val event = RoleChangedEvent(
            chatRoomId = chatRoomId,
            userId = userId,
            newRole = newRole
        )

        val destination = "/topic/chat/$chatRoomId"
        messagingTemplate.convertAndSend(destination, event)
        log.debug("Role changed event broadcast to {}: userId={}, newRole={}", destination, userId, newRole)

        // Send to individual user queues for all active members
        val members = chatMemberRepository.findByChatRoomId(chatRoomId)
        members.filter { it.isActive }.forEach { member ->
            val userDestination = "/queue/user/${member.userId}"
            messagingTemplate.convertAndSend(userDestination, event)
        }
    }
}
