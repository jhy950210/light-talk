package com.lighttalk.auth.repository

import com.lighttalk.core.entity.User
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query

interface AuthUserRepository : JpaRepository<User, Long> {
    fun findByPhoneBlindIndex(phoneBlindIndex: String): User?
    fun existsByPhoneBlindIndex(phoneBlindIndex: String): Boolean

    @Query("SELECT MAX(CAST(u.tag AS int)) FROM User u WHERE u.nickname = :nickname")
    fun findMaxTagByNickname(nickname: String): Int?
}
