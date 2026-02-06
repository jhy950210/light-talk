package com.lighttalk.user.repository

import com.lighttalk.core.entity.Friendship
import com.lighttalk.core.entity.FriendshipStatus
import org.springframework.data.jpa.repository.JpaRepository

interface FriendshipRepository : JpaRepository<Friendship, Long> {

    fun findByUserIdAndStatus(userId: Long, status: FriendshipStatus): List<Friendship>

    fun findByFriendIdAndStatus(friendId: Long, status: FriendshipStatus): List<Friendship>

    fun findByUserIdAndFriendId(userId: Long, friendId: Long): Friendship?

    fun existsByUserIdAndFriendId(userId: Long, friendId: Long): Boolean
}
