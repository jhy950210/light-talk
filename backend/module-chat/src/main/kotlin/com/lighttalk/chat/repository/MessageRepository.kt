package com.lighttalk.chat.repository

import com.lighttalk.core.entity.Message
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface MessageRepository : JpaRepository<Message, Long> {

    @Query("""
        SELECT m FROM Message m
        WHERE m.chatRoomId = :chatRoomId
        AND m.id < :cursor
        AND m.createdAt >= :since
        ORDER BY m.id DESC
    """)
    fun findByChatRoomIdWithCursor(
        @Param("chatRoomId") chatRoomId: Long,
        @Param("cursor") cursor: Long,
        @Param("since") since: LocalDateTime,
        @Param("size") size: org.springframework.data.domain.Pageable
    ): List<Message>

    @Query("""
        SELECT m FROM Message m
        WHERE m.chatRoomId = :chatRoomId
        AND m.createdAt >= :since
        ORDER BY m.id DESC
    """)
    fun findByChatRoomIdLatest(
        @Param("chatRoomId") chatRoomId: Long,
        @Param("since") since: LocalDateTime,
        size: org.springframework.data.domain.Pageable
    ): List<Message>

    @Query("""
        SELECT m FROM Message m
        WHERE m.chatRoomId = :chatRoomId
        ORDER BY m.id DESC
        LIMIT 1
    """)
    fun findLastByChatRoomId(@Param("chatRoomId") chatRoomId: Long): Message?

    @Query("""
        SELECT COUNT(m) FROM Message m
        WHERE m.chatRoomId = :chatRoomId
        AND m.id > :lastReadMessageId
        AND m.createdAt >= :since
    """)
    fun countUnreadMessages(
        @Param("chatRoomId") chatRoomId: Long,
        @Param("lastReadMessageId") lastReadMessageId: Long,
        @Param("since") since: LocalDateTime
    ): Long

    @Query("""
        SELECT cm.chat_room_id AS roomId, COUNT(m.id) AS cnt
        FROM chat_members cm
        LEFT JOIN messages m ON m.chat_room_id = cm.chat_room_id
            AND m.id > COALESCE(cm.last_read_message_id, 0)
            AND m.created_at >= cm.joined_at
        WHERE cm.user_id = :userId AND cm.left_at IS NULL
        GROUP BY cm.chat_room_id
    """, nativeQuery = true)
    fun countUnreadByUserGroupedByRoom(@Param("userId") userId: Long): List<Array<Any>>

    @Query("""
        SELECT m FROM Message m
        WHERE m.id IN (
            SELECT MAX(m2.id) FROM Message m2
            WHERE m2.chatRoomId IN :chatRoomIds
            GROUP BY m2.chatRoomId
        )
    """)
    fun findLastMessagesByRoomIds(@Param("chatRoomIds") chatRoomIds: List<Long>): List<Message>

    @Query("""
        SELECT COALESCE(SUM(cnt), 0) FROM (
            SELECT COUNT(m.id) AS cnt
            FROM chat_members cm
            JOIN messages m ON m.chat_room_id = cm.chat_room_id
                AND m.id > COALESCE(cm.last_read_message_id, 0)
                AND m.created_at >= cm.joined_at
            WHERE cm.user_id = :userId AND cm.left_at IS NULL
            GROUP BY cm.chat_room_id
        ) sub
    """, nativeQuery = true)
    fun countTotalUnreadByUserId(@Param("userId") userId: Long): Long
}
