package com.lighttalk.user.service

import com.lighttalk.core.config.RedisKeyConstants
import org.springframework.data.redis.core.RedisTemplate
import org.springframework.stereotype.Service

@Service
class OnlineStatusService(
    private val redisTemplate: RedisTemplate<String, String>
) {

    fun setOnline(userId: Long) {
        redisTemplate.opsForSet().add(RedisKeyConstants.ONLINE_USERS_KEY, userId.toString())
    }

    fun setOffline(userId: Long) {
        redisTemplate.opsForSet().remove(RedisKeyConstants.ONLINE_USERS_KEY, userId.toString())
    }

    fun isOnline(userId: Long): Boolean {
        return redisTemplate.opsForSet().isMember(RedisKeyConstants.ONLINE_USERS_KEY, userId.toString()) ?: false
    }

    fun getOnlineUserIds(userIds: List<Long>): Set<Long> {
        if (userIds.isEmpty()) return emptySet()

        val stringIds = userIds.map { it.toString() }
        val results = redisTemplate.executePipelined { connection ->
            val rawKey = RedisKeyConstants.ONLINE_USERS_KEY.toByteArray()
            stringIds.forEach { id ->
                connection.setCommands().sIsMember(rawKey, id.toByteArray())
            }
            null
        }

        return stringIds.indices
            .filter { results[it] as? Boolean ?: false }
            .map { userIds[it] }
            .toSet()
    }
}
