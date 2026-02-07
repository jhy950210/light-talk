package com.lighttalk.chat.service

import com.lighttalk.chat.dto.ChatMemberInfo
import com.lighttalk.chat.dto.ChatRoomResponse
import com.lighttalk.chat.dto.LastMessageInfo
import com.lighttalk.chat.repository.ChatMemberRepository
import com.lighttalk.chat.repository.ChatRoomRepository
import com.lighttalk.chat.repository.MessageRepository
import com.lighttalk.core.entity.ChatMember
import com.lighttalk.core.entity.ChatRoom
import com.lighttalk.core.entity.ChatRoomType
import com.lighttalk.core.entity.User
import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import jakarta.persistence.EntityManager
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class ChatRoomService(
    private val chatRoomRepository: ChatRoomRepository,
    private val chatMemberRepository: ChatMemberRepository,
    private val messageRepository: MessageRepository,
    private val entityManager: EntityManager
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @Transactional
    fun createDirectChat(userId: Long, targetUserId: Long): ChatRoomResponse {
        if (userId == targetUserId) {
            throw ApiException(ErrorCode.INVALID_INPUT_VALUE, "자기 자신과의 채팅방은 생성할 수 없습니다")
        }

        // Check if direct chat already exists between the two users
        val existingRoomId = chatMemberRepository.findDirectChatRoomId(userId, targetUserId)
        if (existingRoomId != null) {
            return getChatRoom(existingRoomId, userId)
        }

        // Validate both users exist
        val user = entityManager.find(User::class.java, userId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)
        val targetUser = entityManager.find(User::class.java, targetUserId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND, "대상 사용자를 찾을 수 없습니다")

        // Create chat room
        val chatRoom = chatRoomRepository.save(ChatRoom(type = ChatRoomType.DIRECT))

        // Create members
        chatMemberRepository.save(ChatMember(chatRoomId = chatRoom.id, userId = userId))
        chatMemberRepository.save(ChatMember(chatRoomId = chatRoom.id, userId = targetUserId))

        log.info("Created direct chat room: roomId={}, users=[{}, {}]", chatRoom.id, userId, targetUserId)

        return ChatRoomResponse(
            id = chatRoom.id,
            type = chatRoom.type,
            members = listOf(
                ChatMemberInfo(
                    userId = user.id,
                    nickname = user.nickname,
                    profileImageUrl = user.profileImageUrl,
                    joinedAt = chatRoom.createdAt
                ),
                ChatMemberInfo(
                    userId = targetUser.id,
                    nickname = targetUser.nickname,
                    profileImageUrl = targetUser.profileImageUrl,
                    joinedAt = chatRoom.createdAt
                )
            ),
            lastMessage = null,
            unreadCount = 0
        )
    }

    fun getMyChatRooms(userId: Long): List<ChatRoomResponse> {
        val myMemberships = chatMemberRepository.findByUserId(userId)
        if (myMemberships.isEmpty()) {
            return emptyList()
        }

        return myMemberships.map { membership ->
            val chatRoom = chatRoomRepository.findById(membership.chatRoomId)
                .orElseThrow { ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND) }

            buildChatRoomResponse(chatRoom, membership)
        }.sortedByDescending { it.lastMessage?.createdAt ?: java.time.LocalDateTime.MIN }
    }

    fun getChatRoom(roomId: Long, userId: Long): ChatRoomResponse {
        val chatRoom = chatRoomRepository.findById(roomId)
            .orElseThrow { ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND) }

        val membership = chatMemberRepository.findByChatRoomIdAndUserId(roomId, userId)
            ?: throw ApiException(ErrorCode.NOT_CHAT_MEMBER)

        return buildChatRoomResponse(chatRoom, membership)
    }

    private fun buildChatRoomResponse(chatRoom: ChatRoom, currentMembership: ChatMember): ChatRoomResponse {
        val members = chatMemberRepository.findByChatRoomId(chatRoom.id)

        val memberInfos = members.map { member ->
            val user = entityManager.find(User::class.java, member.userId)
            ChatMemberInfo(
                userId = member.userId,
                nickname = user?.nickname ?: "Unknown",
                profileImageUrl = user?.profileImageUrl,
                joinedAt = member.joinedAt
            )
        }

        val lastMessage = messageRepository.findLastByChatRoomId(chatRoom.id)
        val lastMessageInfo = lastMessage?.let {
            LastMessageInfo(
                id = it.id,
                content = if (it.isDeleted) "" else it.content,
                senderId = it.senderId,
                type = it.type.name,
                createdAt = it.createdAt
            )
        }

        val unreadCount = if (currentMembership.lastReadMessageId != null) {
            messageRepository.countUnreadMessages(chatRoom.id, currentMembership.lastReadMessageId!!)
        } else {
            // If never read, count all messages
            messageRepository.countUnreadMessages(chatRoom.id, 0L)
        }

        return ChatRoomResponse(
            id = chatRoom.id,
            type = chatRoom.type,
            members = memberInfos,
            lastMessage = lastMessageInfo,
            unreadCount = unreadCount
        )
    }
}
