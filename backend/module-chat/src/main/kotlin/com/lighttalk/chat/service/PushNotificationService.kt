package com.lighttalk.chat.service

/**
 * Interface for push notification delivery.
 * Implementations can use FCM, APNs, or other push providers.
 */
interface PushNotificationService {

    fun sendPushNotification(userId: Long, title: String, body: String, badgeCount: Int = 0, chatRoomId: Long? = null)
}
