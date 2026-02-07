package com.lighttalk.core.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Table
import java.time.LocalDateTime

@Entity
@Table(name = "messages")
class Message(

    @Column(name = "chat_room_id", nullable = false)
    val chatRoomId: Long,

    @Column(name = "sender_id", nullable = false)
    val senderId: Long,

    @Column(nullable = false, columnDefinition = "TEXT")
    val content: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: MessageType = MessageType.TEXT,

    @Column(name = "deleted_at")
    var deletedAt: LocalDateTime? = null

) : BaseEntity() {

    val isDeleted: Boolean
        get() = deletedAt != null

    fun canBeDeletedBy(userId: Long): Boolean = senderId == userId

    fun isWithinDeleteWindow(): Boolean {
        val fiveMinutesAgo = LocalDateTime.now().minusMinutes(5)
        return createdAt.isAfter(fiveMinutesAgo)
    }

    fun softDelete() {
        deletedAt = LocalDateTime.now()
    }
}

enum class MessageType {
    TEXT,
    IMAGE,
    VIDEO,
    SYSTEM
}
