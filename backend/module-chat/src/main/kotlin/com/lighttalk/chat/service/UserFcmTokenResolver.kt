package com.lighttalk.chat.service

/**
 * Resolves FCM tokens for users. This interface breaks the direct dependency
 * from module-chat to module-user's UserRepository.
 */
interface UserFcmTokenResolver {
    fun getFcmToken(userId: Long): String?
    fun getFcmTokens(userIds: List<Long>): Map<Long, String>
}
