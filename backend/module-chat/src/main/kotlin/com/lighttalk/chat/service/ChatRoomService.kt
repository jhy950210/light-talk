package com.lighttalk.chat.service

import com.lighttalk.chat.dto.ChatMemberInfo
import com.lighttalk.chat.dto.ChatRoomResponse
import com.lighttalk.chat.dto.LastMessageInfo
import com.lighttalk.chat.repository.ChatMemberRepository
import com.lighttalk.chat.repository.ChatRoomRepository
import com.lighttalk.chat.repository.MessageRepository
import com.lighttalk.core.entity.ChatMember
import com.lighttalk.core.entity.ChatMemberRole
import com.lighttalk.core.entity.ChatRoom
import com.lighttalk.core.entity.ChatRoomType
import com.lighttalk.core.entity.Message
import com.lighttalk.core.entity.MessageType
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
    private val chatNotificationService: ChatNotificationService,
    private val entityManager: EntityManager
) {

    private val log = LoggerFactory.getLogger(javaClass)

    companion object {
        const val DEFAULT_GROUP_MAX_MEMBERS = 100
    }

    // ─── Direct Chat ─────────────────────────────────────────────

    @Transactional
    fun createDirectChat(userId: Long, targetUserId: Long): ChatRoomResponse {
        if (userId == targetUserId) {
            throw ApiException(ErrorCode.INVALID_INPUT_VALUE, "자기 자신과의 채팅방은 생성할 수 없습니다")
        }

        val existingRoomId = chatMemberRepository.findDirectChatRoomId(userId, targetUserId)
        if (existingRoomId != null) {
            return getChatRoom(existingRoomId, userId)
        }

        val user = entityManager.find(User::class.java, userId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)
        val targetUser = entityManager.find(User::class.java, targetUserId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND, "대상 사용자를 찾을 수 없습니다")

        val chatRoom = chatRoomRepository.save(ChatRoom(type = ChatRoomType.DIRECT))

        chatMemberRepository.save(ChatMember(chatRoomId = chatRoom.id, userId = userId))
        chatMemberRepository.save(ChatMember(chatRoomId = chatRoom.id, userId = targetUserId))

        log.info("Created direct chat room: roomId={}, users=[{}, {}]", chatRoom.id, userId, targetUserId)

        return ChatRoomResponse(
            id = chatRoom.id,
            type = chatRoom.type,
            name = chatRoom.name,
            imageUrl = chatRoom.imageUrl,
            ownerId = chatRoom.ownerId,
            maxMembers = chatRoom.maxMembers,
            members = listOf(
                ChatMemberInfo(
                    userId = user.id,
                    nickname = user.nickname,
                    profileImageUrl = user.profileImageUrl,
                    joinedAt = chatRoom.createdAt,
                    role = ChatMemberRole.MEMBER
                ),
                ChatMemberInfo(
                    userId = targetUser.id,
                    nickname = targetUser.nickname,
                    profileImageUrl = targetUser.profileImageUrl,
                    joinedAt = chatRoom.createdAt,
                    role = ChatMemberRole.MEMBER
                )
            ),
            lastMessage = null,
            unreadCount = 0
        )
    }

    // ─── Group Chat ──────────────────────────────────────────────

    @Transactional
    fun createGroupChat(ownerId: Long, name: String, memberIds: List<Long>, imageUrl: String?): ChatRoomResponse {
        if (name.isBlank()) {
            throw ApiException(ErrorCode.GROUP_CHAT_NAME_REQUIRED)
        }

        val uniqueMemberIds = memberIds.distinct().filter { it != ownerId }
        if (uniqueMemberIds.isEmpty()) {
            throw ApiException(ErrorCode.GROUP_CHAT_MIN_MEMBERS)
        }

        val totalMembers = uniqueMemberIds.size + 1
        if (totalMembers > DEFAULT_GROUP_MAX_MEMBERS) {
            throw ApiException(ErrorCode.GROUP_CHAT_MAX_MEMBERS)
        }

        val owner = entityManager.find(User::class.java, ownerId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)

        val memberUsers = uniqueMemberIds.map { memberId ->
            entityManager.find(User::class.java, memberId)
                ?: throw ApiException(ErrorCode.USER_NOT_FOUND, "사용자(ID: $memberId)를 찾을 수 없습니다")
        }

        val chatRoom = chatRoomRepository.save(
            ChatRoom(
                type = ChatRoomType.GROUP,
                name = name,
                ownerId = ownerId,
                maxMembers = DEFAULT_GROUP_MAX_MEMBERS,
                imageUrl = imageUrl
            )
        )

        chatMemberRepository.save(
            ChatMember(chatRoomId = chatRoom.id, userId = ownerId, role = ChatMemberRole.OWNER)
        )

        memberUsers.forEach { user ->
            chatMemberRepository.save(
                ChatMember(chatRoomId = chatRoom.id, userId = user.id, role = ChatMemberRole.MEMBER)
            )
        }

        val systemMessage = messageRepository.save(
            Message(
                chatRoomId = chatRoom.id,
                senderId = ownerId,
                content = "${owner.nickname}님이 그룹을 만들었습니다.",
                type = MessageType.SYSTEM
            )
        )

        log.info("Created group chat room: roomId={}, owner={}, members={}", chatRoom.id, ownerId, uniqueMemberIds)

        // Notify all members about the new group
        val newMemberInfos = memberUsers.map { user ->
            ChatMemberInfo(
                userId = user.id,
                nickname = user.nickname,
                profileImageUrl = user.profileImageUrl,
                joinedAt = chatRoom.createdAt,
                role = ChatMemberRole.MEMBER
            )
        }
        val ownerInfo = ChatMemberInfo(
            userId = owner.id,
            nickname = owner.nickname,
            profileImageUrl = owner.profileImageUrl,
            joinedAt = chatRoom.createdAt,
            role = ChatMemberRole.OWNER
        )
        chatNotificationService.notifyMemberJoined(chatRoom.id, listOf(ownerInfo) + newMemberInfos)

        val allMemberInfos = mutableListOf(
            ChatMemberInfo(
                userId = owner.id,
                nickname = owner.nickname,
                profileImageUrl = owner.profileImageUrl,
                joinedAt = chatRoom.createdAt,
                role = ChatMemberRole.OWNER
            )
        )
        allMemberInfos.addAll(memberUsers.map { user ->
            ChatMemberInfo(
                userId = user.id,
                nickname = user.nickname,
                profileImageUrl = user.profileImageUrl,
                joinedAt = chatRoom.createdAt,
                role = ChatMemberRole.MEMBER
            )
        })

        return ChatRoomResponse(
            id = chatRoom.id,
            type = chatRoom.type,
            name = chatRoom.name,
            imageUrl = chatRoom.imageUrl,
            ownerId = chatRoom.ownerId,
            maxMembers = chatRoom.maxMembers,
            members = allMemberInfos,
            lastMessage = LastMessageInfo(
                id = systemMessage.id,
                content = systemMessage.content,
                senderId = systemMessage.senderId,
                type = systemMessage.type.name,
                createdAt = systemMessage.createdAt
            ),
            unreadCount = 0
        )
    }

    @Transactional
    fun inviteMembers(roomId: Long, inviterId: Long, memberIds: List<Long>): ChatRoomResponse {
        val chatRoom = chatRoomRepository.findById(roomId)
            .orElseThrow { ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND) }

        if (chatRoom.type != ChatRoomType.GROUP) {
            throw ApiException(ErrorCode.CANNOT_MODIFY_DIRECT_CHAT)
        }

        val inviter = getActiveMemberOrThrow(roomId, inviterId)
        requireAdminOrOwner(inviter)

        val inviterUser = entityManager.find(User::class.java, inviterId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)

        val currentCount = chatMemberRepository.countActiveByChatRoomId(roomId)
        val uniqueNewIds = memberIds.distinct()

        if (currentCount + uniqueNewIds.size > chatRoom.maxMembers) {
            throw ApiException(ErrorCode.GROUP_CHAT_MAX_MEMBERS)
        }

        val joinedMemberInfos = mutableListOf<ChatMemberInfo>()

        for (memberId in uniqueNewIds) {
            val existing = chatMemberRepository.findByChatRoomIdAndUserId(roomId, memberId)
            if (existing != null && existing.isActive) {
                continue
            }

            val user = entityManager.find(User::class.java, memberId)
                ?: throw ApiException(ErrorCode.USER_NOT_FOUND, "사용자(ID: $memberId)를 찾을 수 없습니다")

            if (existing != null && !existing.isActive) {
                existing.leftAt = null
                existing.role = ChatMemberRole.MEMBER
                chatMemberRepository.save(existing)
            } else {
                chatMemberRepository.save(
                    ChatMember(chatRoomId = roomId, userId = memberId, role = ChatMemberRole.MEMBER)
                )
            }

            joinedMemberInfos.add(
                ChatMemberInfo(
                    userId = user.id,
                    nickname = user.nickname,
                    profileImageUrl = user.profileImageUrl,
                    joinedAt = java.time.LocalDateTime.now(),
                    role = ChatMemberRole.MEMBER
                )
            )
        }

        if (joinedMemberInfos.isNotEmpty()) {
            val names = joinedMemberInfos.joinToString(", ") { it.nickname }
            messageRepository.save(
                Message(
                    chatRoomId = roomId,
                    senderId = inviterId,
                    content = "${inviterUser.nickname}님이 ${names}님을 초대했습니다.",
                    type = MessageType.SYSTEM
                )
            )

            chatNotificationService.notifyMemberJoined(roomId, joinedMemberInfos)
        }

        log.info("Members invited to room {}: {}", roomId, joinedMemberInfos.map { it.userId })

        return getChatRoom(roomId, inviterId)
    }

    @Transactional
    fun removeMember(roomId: Long, requesterId: Long, targetId: Long) {
        val chatRoom = chatRoomRepository.findById(roomId)
            .orElseThrow { ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND) }

        if (chatRoom.type != ChatRoomType.GROUP) {
            throw ApiException(ErrorCode.CANNOT_MODIFY_DIRECT_CHAT)
        }

        val requester = getActiveMemberOrThrow(roomId, requesterId)
        if (requester.role != ChatMemberRole.OWNER) {
            throw ApiException(ErrorCode.NOT_CHAT_OWNER)
        }

        if (requesterId == targetId) {
            throw ApiException(ErrorCode.INVALID_INPUT_VALUE, "자기 자신을 추방할 수 없습니다")
        }

        val target = getActiveMemberOrThrow(roomId, targetId)

        val targetUser = entityManager.find(User::class.java, targetId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)
        val requesterUser = entityManager.find(User::class.java, requesterId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)

        target.leftAt = java.time.LocalDateTime.now()
        chatMemberRepository.save(target)

        messageRepository.save(
            Message(
                chatRoomId = roomId,
                senderId = requesterId,
                content = "${requesterUser.nickname}님이 ${targetUser.nickname}님을 내보냈습니다.",
                type = MessageType.SYSTEM
            )
        )

        chatNotificationService.notifyMemberLeft(roomId, targetId, null)

        log.info("Member {} kicked from room {} by {}", targetId, roomId, requesterId)
    }

    @Transactional
    fun leaveRoom(roomId: Long, userId: Long) {
        val chatRoom = chatRoomRepository.findById(roomId)
            .orElseThrow { ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND) }

        if (chatRoom.type != ChatRoomType.GROUP) {
            throw ApiException(ErrorCode.CANNOT_LEAVE_DIRECT_CHAT)
        }

        val member = getActiveMemberOrThrow(roomId, userId)
        val user = entityManager.find(User::class.java, userId)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)

        var newOwnerId: Long? = null

        if (member.role == ChatMemberRole.OWNER) {
            val candidates = chatMemberRepository.findNextOwnerCandidate(roomId, userId)
            if (candidates.isNotEmpty()) {
                val newOwner = candidates.first()
                newOwner.role = ChatMemberRole.OWNER
                chatMemberRepository.save(newOwner)
                chatRoom.ownerId = newOwner.userId
                chatRoomRepository.save(chatRoom)
                newOwnerId = newOwner.userId

                val newOwnerUser = entityManager.find(User::class.java, newOwner.userId)
                messageRepository.save(
                    Message(
                        chatRoomId = roomId,
                        senderId = userId,
                        content = "${newOwnerUser?.nickname ?: "Unknown"}님이 새로운 방장이 되었습니다.",
                        type = MessageType.SYSTEM
                    )
                )

                chatNotificationService.notifyRoleChanged(roomId, newOwner.userId, ChatMemberRole.OWNER)

                log.info("Owner transferred in room {}: {} -> {}", roomId, userId, newOwner.userId)
            }
        }

        member.leftAt = java.time.LocalDateTime.now()
        chatMemberRepository.save(member)

        messageRepository.save(
            Message(
                chatRoomId = roomId,
                senderId = userId,
                content = "${user.nickname}님이 나갔습니다.",
                type = MessageType.SYSTEM
            )
        )

        chatNotificationService.notifyMemberLeft(roomId, userId, newOwnerId)

        log.info("Member {} left room {}", userId, roomId)
    }

    @Transactional
    fun updateRoom(roomId: Long, userId: Long, name: String?, imageUrl: String?): ChatRoomResponse {
        val chatRoom = chatRoomRepository.findById(roomId)
            .orElseThrow { ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND) }

        if (chatRoom.type != ChatRoomType.GROUP) {
            throw ApiException(ErrorCode.CANNOT_MODIFY_DIRECT_CHAT)
        }

        val member = getActiveMemberOrThrow(roomId, userId)
        requireAdminOrOwner(member)

        if (name != null) {
            if (name.isBlank()) {
                throw ApiException(ErrorCode.GROUP_CHAT_NAME_REQUIRED)
            }
            chatRoom.name = name
        }
        if (imageUrl != null) {
            chatRoom.imageUrl = imageUrl
        }

        chatRoomRepository.save(chatRoom)

        val requesterUser = entityManager.find(User::class.java, userId)
        if (name != null) {
            messageRepository.save(
                Message(
                    chatRoomId = roomId,
                    senderId = userId,
                    content = "${requesterUser?.nickname ?: "Unknown"}님이 방 이름을 '${chatRoom.name}'(으)로 변경했습니다.",
                    type = MessageType.SYSTEM
                )
            )
        }

        chatNotificationService.notifyChatRoomUpdated(roomId, chatRoom.name, chatRoom.imageUrl)

        log.info("Room {} updated by {}: name={}, imageUrl={}", roomId, userId, name, imageUrl)

        return getChatRoom(roomId, userId)
    }

    @Transactional
    fun changeRole(roomId: Long, requesterId: Long, targetId: Long, newRoleStr: String) {
        val chatRoom = chatRoomRepository.findById(roomId)
            .orElseThrow { ApiException(ErrorCode.CHAT_ROOM_NOT_FOUND) }

        if (chatRoom.type != ChatRoomType.GROUP) {
            throw ApiException(ErrorCode.CANNOT_MODIFY_DIRECT_CHAT)
        }

        val requester = getActiveMemberOrThrow(roomId, requesterId)
        if (requester.role != ChatMemberRole.OWNER) {
            throw ApiException(ErrorCode.NOT_CHAT_OWNER)
        }

        if (requesterId == targetId) {
            throw ApiException(ErrorCode.CANNOT_CHANGE_OWN_ROLE)
        }

        val newRole = try {
            ChatMemberRole.valueOf(newRoleStr.uppercase())
        } catch (e: IllegalArgumentException) {
            throw ApiException(ErrorCode.INVALID_ROLE)
        }

        val target = getActiveMemberOrThrow(roomId, targetId)

        if (newRole == ChatMemberRole.OWNER) {
            // Transfer ownership
            requester.role = ChatMemberRole.ADMIN
            chatMemberRepository.save(requester)

            target.role = ChatMemberRole.OWNER
            chatMemberRepository.save(target)

            chatRoom.ownerId = targetId
            chatRoomRepository.save(chatRoom)

            val targetUser = entityManager.find(User::class.java, targetId)
            messageRepository.save(
                Message(
                    chatRoomId = roomId,
                    senderId = requesterId,
                    content = "${targetUser?.nickname ?: "Unknown"}님에게 방장을 위임했습니다.",
                    type = MessageType.SYSTEM
                )
            )

            chatNotificationService.notifyRoleChanged(roomId, requesterId, ChatMemberRole.ADMIN)
            log.info("Ownership transferred in room {}: {} -> {}", roomId, requesterId, targetId)
        } else {
            target.role = newRole
            chatMemberRepository.save(target)
            log.info("Role changed in room {}: user {} -> {}", roomId, targetId, newRole)
        }

        chatNotificationService.notifyRoleChanged(roomId, targetId, newRole)
    }

    // ─── Read operations ─────────────────────────────────────────

    fun getMyChatRooms(userId: Long): List<ChatRoomResponse> {
        val myMemberships = chatMemberRepository.findByUserId(userId)
            .filter { it.isActive }
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

    // ─── Helpers ─────────────────────────────────────────────────

    private fun buildChatRoomResponse(chatRoom: ChatRoom, currentMembership: ChatMember): ChatRoomResponse {
        val members = chatMemberRepository.findActiveByChatRoomId(chatRoom.id)

        val memberInfos = members.map { member ->
            val user = entityManager.find(User::class.java, member.userId)
            ChatMemberInfo(
                userId = member.userId,
                nickname = user?.nickname ?: "Unknown",
                profileImageUrl = user?.profileImageUrl,
                joinedAt = member.joinedAt,
                role = member.role
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
            messageRepository.countUnreadMessages(chatRoom.id, 0L)
        }

        return ChatRoomResponse(
            id = chatRoom.id,
            type = chatRoom.type,
            name = chatRoom.name,
            imageUrl = chatRoom.imageUrl,
            ownerId = chatRoom.ownerId,
            maxMembers = chatRoom.maxMembers,
            members = memberInfos,
            lastMessage = lastMessageInfo,
            unreadCount = unreadCount
        )
    }

    private fun getActiveMemberOrThrow(roomId: Long, userId: Long): ChatMember {
        return chatMemberRepository.findActiveByChatRoomIdAndUserId(roomId, userId)
            ?: throw ApiException(ErrorCode.NOT_CHAT_MEMBER)
    }

    private fun requireAdminOrOwner(member: ChatMember) {
        if (member.role != ChatMemberRole.OWNER && member.role != ChatMemberRole.ADMIN) {
            throw ApiException(ErrorCode.NOT_CHAT_ADMIN)
        }
    }
}
