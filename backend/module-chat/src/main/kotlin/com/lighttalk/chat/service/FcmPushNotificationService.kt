package com.lighttalk.chat.service

import com.google.firebase.messaging.AndroidConfig
import com.google.firebase.messaging.AndroidNotification
import com.google.firebase.messaging.ApnsConfig
import com.google.firebase.messaging.Aps
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.Message
import com.google.firebase.messaging.Notification
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Service

/**
 * FCM implementation of PushNotificationService.
 * Activated when push.notification.provider=fcm.
 */
@Service
@ConditionalOnProperty(
    name = ["push.notification.provider"],
    havingValue = "fcm"
)
class FcmPushNotificationService(
    private val userFcmTokenResolver: UserFcmTokenResolver
) : PushNotificationService {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun sendPushNotification(userId: Long, title: String, body: String, badgeCount: Int, chatRoomId: Long?) {
        val fcmToken = userFcmTokenResolver.getFcmToken(userId)
        if (fcmToken == null) {
            log.debug("No FCM token for userId={}, skipping push", userId)
            return
        }

        try {
            val message = Message.builder()
                .setToken(fcmToken)
                .setNotification(
                    Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build()
                )
                .setApnsConfig(
                    ApnsConfig.builder()
                        .setAps(
                            Aps.builder()
                                .setSound("default")
                                .setBadge(badgeCount)
                                .build()
                        )
                        .build()
                )
                .setAndroidConfig(
                    AndroidConfig.builder()
                        .setPriority(AndroidConfig.Priority.HIGH)
                        .setNotification(
                            AndroidNotification.builder()
                                .setSound("default")
                                .setPriority(AndroidNotification.Priority.HIGH)
                                .build()
                        )
                        .build()
                )
                .putData("type", "chat_message")
                .putData("userId", userId.toString())
                .apply { if (chatRoomId != null) putData("chatRoomId", chatRoomId.toString()) }
                .build()

            val messageId = FirebaseMessaging.getInstance().send(message)
            log.debug("FCM push sent to userId={}, messageId={}", userId, messageId)
        } catch (e: Exception) {
            log.warn("Failed to send FCM push to userId={}: {}", userId, e.message)
        }
    }
}
