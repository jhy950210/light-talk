package com.lighttalk.chat.service

import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Service

/**
 * Stub implementation of PushNotificationService that only logs.
 * Used when push.notification.provider is not set to "fcm".
 */
@Service
@ConditionalOnProperty(
    name = ["push.notification.provider"],
    havingValue = "stub",
    matchIfMissing = true
)
class StubPushNotificationService : PushNotificationService {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun sendPushNotification(userId: Long, title: String, body: String, badgeCount: Int, chatRoomId: Long?) {
        log.info(
            "[STUB PUSH] Sending push notification to userId={}, title='{}', body='{}'",
            userId, title, body
        )
    }
}
