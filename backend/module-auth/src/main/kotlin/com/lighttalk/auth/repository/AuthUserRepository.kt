package com.lighttalk.auth.repository

import com.lighttalk.core.entity.User
import org.springframework.data.jpa.repository.JpaRepository

interface AuthUserRepository : JpaRepository<User, Long> {

    fun findByEmail(email: String): User?

    fun existsByEmail(email: String): Boolean
}
