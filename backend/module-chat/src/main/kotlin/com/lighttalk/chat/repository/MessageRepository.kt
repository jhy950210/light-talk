package com.lighttalk.chat.repository

import com.lighttalk.core.entity.Message
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface MessageRepository : JpaRepository<Message, Long> {

    @Query("""
        SELECT m FROM Message m
        WHERE m.chatRoomId = :chatRoomId
        AND m.id < :cursor
        ORDER BY m.id DESC
    """)
    fun findByChatRoomIdWithCursor(
        @Param("chatRoomId") chatRoomId: Long,
        @Param("cursor") cursor: Long,
        @Param("size") size: org.springframework.data.domain.Pageable
    ): List<Message>

    @Query("""
        SELECT m FROM Message m
        WHERE m.chatRoomId = :chatRoomId
        ORDER BY m.id DESC
    """)
    fun findByChatRoomIdLatest(
        @Param("chatRoomId") chatRoomId: Long,
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
    """)
    fun countUnreadMessages(
        @Param("chatRoomId") chatRoomId: Long,
        @Param("lastReadMessageId") lastReadMessageId: Long
    ): Long
}
