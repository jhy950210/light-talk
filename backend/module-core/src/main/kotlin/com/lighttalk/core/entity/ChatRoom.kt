package com.lighttalk.core.entity

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Table

@Entity
@Table(name = "chat_rooms")
class ChatRoom(

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: ChatRoomType = ChatRoomType.DIRECT

) : BaseEntity()

enum class ChatRoomType {
    DIRECT
}
