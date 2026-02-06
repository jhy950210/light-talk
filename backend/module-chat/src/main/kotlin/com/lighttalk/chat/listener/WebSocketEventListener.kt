package com.lighttalk.chat.listener

import org.slf4j.LoggerFactory
import org.springframework.context.event.EventListener
import org.springframework.data.redis.core.RedisTemplate
import org.springframework.messaging.simp.stomp.StompHeaderAccessor
import org.springframework.stereotype.Component
import org.springframework.web.socket.messaging.SessionConnectEvent
import org.springframework.web.socket.messaging.SessionDisconnectEvent

@Component
class WebSocketEventListener(
    private val redisTemplate: RedisTemplate<String, String>
) {

    private val log = LoggerFactory.getLogger(javaClass)

    companion object {
        private const val ONLINE_USERS_KEY = "online:users"
        private const val USER_SESSION_PREFIX = "online:session:"
    }

    @EventListener
    fun handleSessionConnect(event: SessionConnectEvent) {
        val accessor = StompHeaderAccessor.wrap(event.message)
        val userId = accessor.user?.name ?: return
        val sessionId = accessor.sessionId ?: return

        // Store mapping: sessionId -> userId
        redisTemplate.opsForValue().set("$USER_SESSION_PREFIX$sessionId", userId)

        // Add userId to online set
        redisTemplate.opsForSet().add(ONLINE_USERS_KEY, userId)

        log.info("User connected: userId={}, sessionId={}", userId, sessionId)
    }

    @EventListener
    fun handleSessionDisconnect(event: SessionDisconnectEvent) {
        val accessor = StompHeaderAccessor.wrap(event.message)
        val sessionId = accessor.sessionId ?: return

        // Retrieve userId from session mapping
        val userId = redisTemplate.opsForValue().get("$USER_SESSION_PREFIX$sessionId")
        if (userId != null) {
            // Remove session mapping
            redisTemplate.delete("$USER_SESSION_PREFIX$sessionId")

            // Remove from online set
            redisTemplate.opsForSet().remove(ONLINE_USERS_KEY, userId)

            log.info("User disconnected: userId={}, sessionId={}", userId, sessionId)
        } else {
            log.warn("Disconnect event for unknown session: sessionId={}", sessionId)
        }
    }
}
