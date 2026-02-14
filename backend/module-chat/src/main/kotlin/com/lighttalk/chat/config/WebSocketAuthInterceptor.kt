package com.lighttalk.chat.config

import com.lighttalk.chat.repository.ChatMemberRepository
import com.lighttalk.core.auth.TokenValidator
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
class WebSocketAuthInterceptor(
    private val tokenValidator: TokenValidator,
    private val chatMemberRepository: ChatMemberRepository
) : ChannelInterceptor {

    private val log = LoggerFactory.getLogger(javaClass)

    companion object {
        private val TOPIC_CHAT_PATTERN = Regex("^/topic/chat/(\\d+)$")
        private val QUEUE_USER_PATTERN = Regex("^/queue/user/(\\d+)$")
    }

    override fun preSend(message: Message<*>, channel: MessageChannel): Message<*> {
        val accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor::class.java)
            ?: return message

        when (accessor.command) {
            StompCommand.CONNECT -> handleConnect(accessor)
            StompCommand.SUBSCRIBE -> handleSubscribe(accessor)
            else -> {}
        }

        return message
    }

    private fun handleConnect(accessor: StompHeaderAccessor) {
        val token = accessor.getFirstNativeHeader("Authorization")
            ?.removePrefix("Bearer ")

        if (token.isNullOrBlank()) {
            log.warn("WebSocket CONNECT without Authorization header")
            throw IllegalArgumentException("Authorization header is required")
        }

        val userId = try {
            tokenValidator.validateAndExtractUserId(token)
        } catch (e: Exception) {
            log.warn("WebSocket CONNECT with invalid token: {}", e.message)
            throw IllegalArgumentException("Invalid or expired token")
        }

        accessor.user = StompPrincipal(userId.toString())
        log.debug("WebSocket CONNECT authenticated: userId={}", userId)
    }

    private fun handleSubscribe(accessor: StompHeaderAccessor) {
        val userId = accessor.user?.name?.toLongOrNull()
            ?: throw IllegalArgumentException("Not authenticated")

        val destination = accessor.destination
            ?: throw IllegalArgumentException("Subscription destination is required")

        val topicMatch = TOPIC_CHAT_PATTERN.matchEntire(destination)
        if (topicMatch != null) {
            val roomId = topicMatch.groupValues[1].toLong()
            val member = chatMemberRepository.findActiveByChatRoomIdAndUserId(roomId, userId)
            if (member == null) {
                log.warn("Unauthorized subscription attempt: userId={}, destination={}", userId, destination)
                throw IllegalArgumentException("Not a member of chat room $roomId")
            }
            return
        }

        val queueMatch = QUEUE_USER_PATTERN.matchEntire(destination)
        if (queueMatch != null) {
            val targetUserId = queueMatch.groupValues[1].toLong()
            if (targetUserId != userId) {
                log.warn("Unauthorized queue subscription: userId={} tried to subscribe to userId={}", userId, targetUserId)
                throw IllegalArgumentException("Cannot subscribe to another user's queue")
            }
            return
        }
    }
}

data class StompPrincipal(private val userId: String) : Principal {
    override fun getName(): String = userId
}
