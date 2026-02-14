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
    val type: ChatRoomType = ChatRoomType.DIRECT,

    @Column(length = 100)
    var name: String? = null,

    @Column(name = "owner_id")
    var ownerId: Long? = null,

    @Column(name = "max_members", nullable = false)
    val maxMembers: Int = 2,

    @Column(name = "image_url")
    var imageUrl: String? = null

) : BaseEntity()

enum class ChatRoomType {
    DIRECT,
    GROUP
}
