package com.lighttalk.chat.service

import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Service

/**
 * Stub implementation of PushNotificationService that only logs.
 * Enabled by default. Set push.notification.enabled=false to disable,
 * or replace with an FCM implementation when push.notification.provider=fcm.
 */
@Service
@ConditionalOnProperty(
    name = ["push.notification.enabled"],
    havingValue = "true",
    matchIfMissing = true
)
class StubPushNotificationService : PushNotificationService {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun sendPushNotification(userId: Long, title: String, body: String) {
        log.info(
            "[STUB PUSH] Sending push notification to userId={}, title='{}', body='{}'",
            userId, title, body
        )
    }
}
