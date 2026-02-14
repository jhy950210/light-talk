package com.lighttalk.chat.repository

import com.lighttalk.core.entity.ChatMember
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface ChatMemberRepository : JpaRepository<ChatMember, Long> {

    fun findByChatRoomId(chatRoomId: Long): List<ChatMember>

    fun findByUserId(userId: Long): List<ChatMember>

    fun findByChatRoomIdAndUserId(chatRoomId: Long, userId: Long): ChatMember?

    @Query("""
        SELECT cm1.chatRoomId FROM ChatMember cm1
        JOIN ChatMember cm2 ON cm1.chatRoomId = cm2.chatRoomId
        JOIN ChatRoom cr ON cr.id = cm1.chatRoomId
        WHERE cm1.userId = :userId1
        AND cm2.userId = :userId2
        AND cr.type = com.lighttalk.core.entity.ChatRoomType.DIRECT
    """)
    fun findDirectChatRoomId(
        @Param("userId1") userId1: Long,
        @Param("userId2") userId2: Long
    ): Long?

    @Query("""
        SELECT cm FROM ChatMember cm
        WHERE cm.chatRoomId = :chatRoomId AND cm.leftAt IS NULL
    """)
    fun findActiveByChatRoomId(@Param("chatRoomId") chatRoomId: Long): List<ChatMember>

    @Query("""
        SELECT cm FROM ChatMember cm
        WHERE cm.chatRoomId IN :chatRoomIds AND cm.leftAt IS NULL
    """)
    fun findActiveByRoomIds(@Param("chatRoomIds") chatRoomIds: List<Long>): List<ChatMember>

    @Query("""
        SELECT cm FROM ChatMember cm
        WHERE cm.chatRoomId = :chatRoomId AND cm.userId = :userId AND cm.leftAt IS NULL
    """)
    fun findActiveByChatRoomIdAndUserId(
        @Param("chatRoomId") chatRoomId: Long,
        @Param("userId") userId: Long
    ): ChatMember?

    @Query("""
        SELECT COUNT(cm) FROM ChatMember cm
        WHERE cm.chatRoomId = :chatRoomId AND cm.leftAt IS NULL
    """)
    fun countActiveByChatRoomId(@Param("chatRoomId") chatRoomId: Long): Long

    @Query("""
        SELECT cm FROM ChatMember cm
        WHERE cm.chatRoomId = :chatRoomId AND cm.leftAt IS NULL AND cm.userId <> :excludeUserId
        ORDER BY
            CASE cm.role WHEN com.lighttalk.core.entity.ChatMemberRole.ADMIN THEN 0
                         WHEN com.lighttalk.core.entity.ChatMemberRole.MEMBER THEN 1
                         ELSE 2 END,
            cm.joinedAt ASC
    """)
    fun findNextOwnerCandidate(
        @Param("chatRoomId") chatRoomId: Long,
        @Param("excludeUserId") excludeUserId: Long
    ): List<ChatMember>
}
