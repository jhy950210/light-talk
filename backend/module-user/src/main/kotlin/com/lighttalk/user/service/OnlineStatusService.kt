package com.lighttalk.user.service

import org.springframework.data.redis.core.RedisTemplate
import org.springframework.stereotype.Service

@Service
class OnlineStatusService(
    private val redisTemplate: RedisTemplate<String, String>
) {

    companion object {
        private const val ONLINE_USERS_KEY = "online:users"
    }

    fun setOnline(userId: Long) {
        redisTemplate.opsForSet().add(ONLINE_USERS_KEY, userId.toString())
    }

    fun setOffline(userId: Long) {
        redisTemplate.opsForSet().remove(ONLINE_USERS_KEY, userId.toString())
    }

    fun isOnline(userId: Long): Boolean {
        return redisTemplate.opsForSet().isMember(ONLINE_USERS_KEY, userId.toString()) ?: false
    }

    fun getOnlineUserIds(userIds: List<Long>): Set<Long> {
        if (userIds.isEmpty()) return emptySet()

        val stringIds = userIds.map { it.toString() }
        return stringIds
            .filter { redisTemplate.opsForSet().isMember(ONLINE_USERS_KEY, it) ?: false }
            .map { it.toLong() }
            .toSet()
    }
}
