package com.lighttalk.chat.service

import com.lighttalk.chat.dto.MessagePageResponse
import com.lighttalk.chat.dto.MessageResponse
import com.lighttalk.chat.dto.SendMessageRequest
import com.lighttalk.chat.repository.ChatMemberRepository
import com.lighttalk.chat.repository.ChatRoomRepository
import com.lighttalk.chat.repository.MessageRepository
import com.lighttalk.core.entity.Message
import com.lighttalk.core.entity.User
import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import jakarta.persistence.EntityManager
import org.slf4j.LoggerFactory
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class MessageService(
    private val messageRepository: MessageRepository,
    private val chatRoomRepository: ChatRoomRepository,
    private val chatMemberRepository: ChatMemberRepository,
    private val entityManager: EntityManager
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Transactional
    fun sendMessage(chatRoomId: Long, senderId: Long, request: SendMessageRequest): MessageResponse {
        // Validate chat room exists
        if (!chatRoomRepository.existsById(chatRoomId)) {
            throw ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND)
        }

        // Validate sender is an active member
        chatMemberRepository.findActiveByChatRoomIdAndUserId(chatRoomId, senderId)
            ?: throw ApiException(ErrorCode.NOT_CHAT_MEMBER)

        val message = Message(
            chatRoomId = chatRoomId,
            senderId = senderId,
            content = request.content,
            type = request.type
        )

        val savedMessage = messageRepository.save(message)
        log.debug("Message saved: id={}, chatRoomId={}, senderId={}", savedMessage.id, chatRoomId, senderId)

        return toMessageResponse(savedMessage)
    }

    fun getMessages(chatRoomId: Long, userId: Long, cursor: Long?, size: Int): MessagePageResponse {
        // Validate chat room exists
        if (!chatRoomRepository.existsById(chatRoomId)) {
            throw ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND)
        }

        // Validate user is an active member
        val membership = chatMemberRepository.findActiveByChatRoomIdAndUserId(chatRoomId, userId)
            ?: throw ApiException(ErrorCode.NOT_CHAT_MEMBER)

        // Only show messages since user's joinedAt (hides old messages after re-joining)
        val since = membership.joinedAt

        // Get all active members' lastReadMessageId to determine read status
        val members = chatMemberRepository.findActiveByChatRoomId(chatRoomId)
        val otherMembersLastRead = members
            .filter { it.userId != userId }
            .mapNotNull { it.lastReadMessageId }

        val clampedSize = size.coerceIn(1, 100)
        val pageable = PageRequest.of(0, clampedSize + 1)
        val messages = if (cursor != null) {
            messageRepository.findByChatRoomIdWithCursor(chatRoomId, cursor, since, pageable)
        } else {
            messageRepository.findByChatRoomIdLatest(chatRoomId, since, pageable)
        }

        val hasMore = messages.size > clampedSize
        val resultMessages = if (hasMore) messages.take(clampedSize) else messages

        val messageResponses = resultMessages.map { toMessageResponse(it, otherMembersLastRead) }

        return MessagePageResponse(
            messages = messageResponses,
            hasMore = hasMore,
            nextCursor = if (hasMore && resultMessages.isNotEmpty()) resultMessages.last().id else null
        )
    }

    @Transactional
    fun markAsRead(chatRoomId: Long, userId: Long, messageId: Long) {
        // Validate chat room exists
        if (!chatRoomRepository.existsById(chatRoomId)) {
            throw ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND)
        }

        val membership = chatMemberRepository.findActiveByChatRoomIdAndUserId(chatRoomId, userId)
            ?: throw ApiException(ErrorCode.NOT_CHAT_MEMBER)

        // Only update if new messageId is greater than current lastReadMessageId
        val currentLastRead = membership.lastReadMessageId ?: 0L
        if (messageId > currentLastRead) {
            membership.lastReadMessageId = messageId
            chatMemberRepository.save(membership)
            log.debug("Read receipt updated: chatRoomId={}, userId={}, messageId={}", chatRoomId, userId, messageId)
        }
    }

    @Transactional
    fun deleteMessage(chatRoomId: Long, messageId: Long, userId: Long) {
        // Validate chat room exists
        if (!chatRoomRepository.existsById(chatRoomId)) {
            throw ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND)
        }

        // Validate user is an active member
        chatMemberRepository.findActiveByChatRoomIdAndUserId(chatRoomId, userId)
            ?: throw ApiException(ErrorCode.NOT_CHAT_MEMBER)

        val message = messageRepository.findById(messageId)
            .orElseThrow { ApiException(ErrorCode.MESSAGE_NOT_FOUND) }

        // Check if already deleted
        if (message.isDeleted) {
            throw ApiException(ErrorCode.MESSAGE_ALREADY_DELETED)
        }

        // Only the sender can delete
        if (!message.canBeDeletedBy(userId)) {
            throw ApiException(ErrorCode.MESSAGE_DELETE_FORBIDDEN)
        }

        // 5-minute window check
        if (!message.isWithinDeleteWindow()) {
            throw ApiException(ErrorCode.MESSAGE_DELETE_EXPIRED)
        }

        message.softDelete()
        messageRepository.save(message)
        log.debug("Message soft-deleted: id={}, chatRoomId={}, userId={}", messageId, chatRoomId, userId)
    }

    private fun toMessageResponse(message: Message, otherMembersLastRead: List<Long> = emptyList()): MessageResponse {
        val sender = entityManager.find(User::class.java, message.senderId)
        val isRead = otherMembersLastRead.any { it >= message.id }
        return MessageResponse(
            id = message.id,
            chatRoomId = message.chatRoomId,
            senderId = message.senderId,
            senderNickname = sender?.nickname ?: "Unknown",
            content = if (message.isDeleted) "" else message.content,
            type = message.type,
            createdAt = message.createdAt,
            isRead = isRead,
            deletedAt = message.deletedAt
        )
    }
}
