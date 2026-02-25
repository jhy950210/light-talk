package com.lighttalk.chat.service

import jakarta.persistence.EntityManager
import org.springframework.stereotype.Component

@Component
class JpaUserFcmTokenResolver(
    private val entityManager: EntityManager
) : UserFcmTokenResolver {

    override fun getFcmToken(userId: Long): String? {
        return entityManager.createQuery(
            "SELECT u.fcmToken FROM User u WHERE u.id = :userId",
            String::class.java
        )
            .setParameter("userId", userId)
            .resultList
            .firstOrNull()
    }

    override fun getFcmTokens(userIds: List<Long>): Map<Long, String> {
        if (userIds.isEmpty()) return emptyMap()
        @Suppress("UNCHECKED_CAST")
        val results = entityManager.createQuery(
            "SELECT u.id, u.fcmToken FROM User u WHERE u.id IN :userIds AND u.fcmToken IS NOT NULL"
        )
            .setParameter("userIds", userIds)
            .resultList as List<Array<Any>>

        return results.associate { (it[0] as Long) to (it[1] as String) }
    }
}
