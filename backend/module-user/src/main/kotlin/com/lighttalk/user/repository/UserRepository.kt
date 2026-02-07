package com.lighttalk.user.repository

import com.lighttalk.core.entity.User
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query

interface UserRepository : JpaRepository<User, Long> {
    fun findByNicknameAndTag(nickname: String, tag: String): User?
    fun findByNicknameContainingIgnoreCase(nickname: String): List<User>

    @Query("SELECT MAX(CAST(u.tag AS int)) FROM User u WHERE u.nickname = :nickname")
    fun findMaxTagByNickname(nickname: String): Int?
}
