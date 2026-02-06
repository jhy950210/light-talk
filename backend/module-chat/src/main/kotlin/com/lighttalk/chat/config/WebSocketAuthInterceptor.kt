package com.lighttalk.chat.config

import org.slf4j.LoggerFactory
import org.springframework.messaging.Message
import org.springframework.messaging.MessageChannel
import org.springframework.messaging.simp.stomp.StompCommand
import org.springframework.messaging.simp.stomp.StompHeaderAccessor
import org.springframework.messaging.support.ChannelInterceptor
import org.springframework.messaging.support.MessageHeaderAccessor
import org.springframework.stereotype.Component
import java.security.Principal

@Component
class WebSocketAuthInterceptor : ChannelInterceptor {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun preSend(message: Message<*>, channel: MessageChannel): Message<*> {
        val accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor::class.java)

        if (accessor != null && StompCommand.CONNECT == accessor.command) {
            val token = accessor.getFirstNativeHeader("Authorization")
                ?.removePrefix("Bearer ")

            if (token.isNullOrBlank()) {
                log.warn("WebSocket CONNECT without Authorization header")
                throw IllegalArgumentException("Authorization header is required")
            }

            val userId = extractUserIdFromToken(token)
            accessor.user = StompPrincipal(userId.toString())
            log.debug("WebSocket CONNECT authenticated: userId={}", userId)
        }

        return message
    }

    /**
     * Extracts user ID from JWT token.
     * This is a simplified implementation. In production, this should use
     * the actual JWT parsing logic from the auth module.
     */
    private fun extractUserIdFromToken(token: String): Long {
        try {
            // Decode the JWT payload (second part) to extract the subject (userId)
            val parts = token.split(".")
            if (parts.size != 3) {
                throw IllegalArgumentException("Invalid JWT format")
            }
            val payload = String(java.util.Base64.getUrlDecoder().decode(parts[1]))
            // Simple JSON parsing for "sub" field
            val subRegex = """"sub"\s*:\s*"?(\d+)"?""".toRegex()
            val match = subRegex.find(payload)
                ?: throw IllegalArgumentException("No subject found in JWT")
            return match.groupValues[1].toLong()
        } catch (e: Exception) {
            log.error("Failed to extract userId from token", e)
            throw IllegalArgumentException("Invalid token")
        }
    }
}

data class StompPrincipal(private val userId: String) : Principal {
    override fun getName(): String = userId
}
