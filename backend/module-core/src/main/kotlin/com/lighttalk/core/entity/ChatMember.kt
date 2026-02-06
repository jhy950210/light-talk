package com.lighttalk.core.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Table
import java.time.LocalDateTime

@Entity
@Table(name = "chat_members")
class ChatMember(

    @Column(name = "chat_room_id", nullable = false)
    val chatRoomId: Long,

    @Column(name = "user_id", nullable = false)
    val userId: Long,

    @Column(name = "joined_at", nullable = false, updatable = false)
    val joinedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "last_read_message_id")
    var lastReadMessageId: Long? = null

) : BaseEntity()
