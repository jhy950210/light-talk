package com.lighttalk.user.service

import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import com.lighttalk.user.dto.UpdateProfileRequest
import com.lighttalk.user.dto.UserResponse
import com.lighttalk.user.repository.UserRepository
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class UserService(
    private val userRepository: UserRepository,
    private val onlineStatusService: OnlineStatusService,
    private val passwordEncoder: PasswordEncoder
) {

    fun getProfile(userId: Long): UserResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { ApiException(ErrorCode.USER_NOT_FOUND) }

        return UserResponse(
            id = user.id,
            nickname = user.nickname,
            tag = user.tag,
            profileImageUrl = user.profileImageUrl,
            isOnline = onlineStatusService.isOnline(user.id)
        )
    }

    @Transactional
    fun updateProfile(userId: Long, request: UpdateProfileRequest): UserResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { ApiException(ErrorCode.USER_NOT_FOUND) }

        request.nickname?.let { user.nickname = it }
        request.profileImageUrl?.let { user.profileImageUrl = it }

        val savedUser = userRepository.save(user)

        return UserResponse(
            id = savedUser.id,
            nickname = savedUser.nickname,
            tag = savedUser.tag,
            profileImageUrl = savedUser.profileImageUrl,
            isOnline = onlineStatusService.isOnline(savedUser.id)
        )
    }

    fun searchUsers(currentUserId: Long, query: String): List<UserResponse> {
        val trimmedQuery = query.trim()

        // If query contains #, search by exact nickname#tag
        if (trimmedQuery.contains("#")) {
            val parts = trimmedQuery.split("#", limit = 2)
            val nickname = parts[0]
            val tag = parts[1]
            val user = userRepository.findByNicknameAndTag(nickname, tag)
                ?: return emptyList()
            if (user.id == currentUserId) return emptyList()
            return listOf(UserResponse(
                id = user.id,
                nickname = user.nickname,
                tag = user.tag,
                profileImageUrl = user.profileImageUrl,
                isOnline = onlineStatusService.isOnline(user.id)
            ))
        }

        // Minimum query length for substring search
        if (trimmedQuery.length < 2) {
            throw ApiException(ErrorCode.SEARCH_QUERY_TOO_SHORT)
        }

        // Otherwise search by nickname substring, limited to 20 results
        val users = userRepository.findByNicknameContainingIgnoreCase(trimmedQuery)
        return users.filter { it.id != currentUserId }
            .take(20)
            .map { user ->
                UserResponse(
                    id = user.id,
                    nickname = user.nickname,
                    tag = user.tag,
                    profileImageUrl = user.profileImageUrl,
                    isOnline = onlineStatusService.isOnline(user.id)
                )
            }
    }

    @Transactional
    fun withdrawUser(userId: Long, password: String) {
        val user = userRepository.findById(userId)
            .orElseThrow { ApiException(ErrorCode.USER_NOT_FOUND) }

        // Verify password
        if (!passwordEncoder.matches(password, user.passwordHash)) {
            throw ApiException(ErrorCode.INVALID_PASSWORD)
        }

        // Clear Redis online status
        onlineStatusService.setOffline(userId)

        // Hard delete user — DB CASCADE handles friendships, chat_members, messages
        userRepository.delete(user)
    }
}
