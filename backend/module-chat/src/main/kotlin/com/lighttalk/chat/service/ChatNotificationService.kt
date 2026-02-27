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
import com.lighttalk.chat.repository.MessageRepository
import com.lighttalk.core.entity.ChatMemberRole
import org.slf4j.LoggerFactory
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.scheduling.annotation.Async
import org.springframework.stereotype.Service

@Service
class ChatNotificationService(
    private val messagingTemplate: SimpMessagingTemplate,
    private val chatMemberRepository: ChatMemberRepository,
    private val messageRepository: MessageRepository,
    private val pushNotificationService: PushNotificationService
) {

    private val log = LoggerFactory.getLogger(javaClass)

    fun notifyNewMessage(message: MessageResponse) {
        val event = ChatMessageEvent(message = message)
        broadcastToRoom(message.chatRoomId, event, excludeUserId = message.senderId)
        sendPushNotifications(message)
        log.debug("Message broadcast: chatRoomId={}, messageId={}", message.chatRoomId, message.id)
    }

    @Async
    fun sendPushNotifications(message: MessageResponse) {
        try {
            val members = chatMemberRepository.findActiveByChatRoomId(message.chatRoomId)
            val recipients = members.filter { it.userId != message.senderId }
            if (recipients.isEmpty()) return

            // Batch: calculate unread counts for all recipients at once
            val unreadCounts = recipients.associate { member ->
                member.userId to messageRepository.countTotalUnreadByUserId(member.userId).toInt()
            }

            recipients.forEach { member ->
                pushNotificationService.sendPushNotification(
                    userId = member.userId,
                    title = message.senderNickname,
                    body = message.content,
                    badgeCount = unreadCounts[member.userId] ?: 1,
                    chatRoomId = message.chatRoomId
                )
            }
        } catch (e: Exception) {
            log.warn("Failed to send push notifications for messageId={}: {}", message.id, e.message)
        }
    }

    fun notifyMessageDeleted(chatRoomId: Long, messageId: Long) {
        val event = MessageDeletedEvent(
            chatRoomId = chatRoomId,
            messageId = messageId
        )
        broadcastToRoom(chatRoomId, event)
        log.debug("Message deleted event: chatRoomId={}, messageId={}", chatRoomId, messageId)
    }

    fun notifyReadReceipt(chatRoomId: Long, userId: Long, messageId: Long) {
        val event = ReadReceiptEvent(
            chatRoomId = chatRoomId,
            userId = userId,
            messageId = messageId
        )
        // Read receipts only go to topic (lightweight, no queue push needed)
        messagingTemplate.convertAndSend("/topic/chat/$chatRoomId", event)
        log.debug("Read receipt broadcast: chatRoomId={}, userId={}, messageId={}", chatRoomId, userId, messageId)
    }

    fun notifyMemberJoined(chatRoomId: Long, newMembers: List<ChatMemberInfo>) {
        val event = MemberJoinedEvent(
            chatRoomId = chatRoomId,
            members = newMembers
        )
        broadcastToRoom(chatRoomId, event)
        log.debug("Member joined event: chatRoomId={}, newMembers={}", chatRoomId, newMembers.map { it.userId })
    }

    fun notifyMemberLeft(chatRoomId: Long, userId: Long, newOwnerId: Long?) {
        val event = MemberLeftEvent(
            chatRoomId = chatRoomId,
            userId = userId,
            newOwnerId = newOwnerId
        )
        broadcastToRoom(chatRoomId, event)
        log.debug("Member left event: chatRoomId={}, userId={}, newOwnerId={}", chatRoomId, userId, newOwnerId)
    }

    fun notifyChatRoomUpdated(chatRoomId: Long, name: String?, imageUrl: String?) {
        val event = ChatRoomUpdatedEvent(
            chatRoomId = chatRoomId,
            name = name,
            imageUrl = imageUrl
        )
        broadcastToRoom(chatRoomId, event)
        log.debug("Chat room updated event: chatRoomId={}, name={}", chatRoomId, name)
    }

    fun notifyRoleChanged(chatRoomId: Long, userId: Long, newRole: ChatMemberRole) {
        val event = RoleChangedEvent(
            chatRoomId = chatRoomId,
            userId = userId,
            newRole = newRole
        )
        broadcastToRoom(chatRoomId, event)
        log.debug("Role changed event: chatRoomId={}, userId={}, newRole={}", chatRoomId, userId, newRole)
    }

    /**
     * Broadcasts an event to the chat room topic and to individual user queues
     * for active members who are not currently subscribed to the room topic.
     *
     * The user queue serves as a notification channel for chat list updates
     * (e.g., new message badge) when the user is not viewing the specific room.
     *
     * @param chatRoomId the chat room to broadcast to
     * @param event the event payload
     * @param excludeUserId optional user to exclude from queue notifications (e.g., the sender)
     */
    private fun broadcastToRoom(chatRoomId: Long, event: Any, excludeUserId: Long? = null) {
        // 1. Broadcast to room topic (for users viewing this chat room)
        messagingTemplate.convertAndSend("/topic/chat/$chatRoomId", event)

        // 2. Send to individual user queues (for chat list updates / push notifications)
        val members = chatMemberRepository.findActiveByChatRoomId(chatRoomId)
        members.filter { excludeUserId == null || it.userId != excludeUserId }
            .forEach { member ->
                messagingTemplate.convertAndSend("/queue/user/${member.userId}", event)
            }
    }
}
