package com.lighttalk.user.service

import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import com.lighttalk.user.dto.UpdateProfileRequest
import com.lighttalk.user.dto.UserResponse
import com.lighttalk.user.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class UserService(
    private val userRepository: UserRepository,
    private val onlineStatusService: OnlineStatusService
) {

    fun getProfile(userId: Long): UserResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { ApiException(ErrorCode.USER_NOT_FOUND) }

        return UserResponse(
            id = user.id,
            email = user.email,
            nickname = user.nickname,
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
            email = savedUser.email,
            nickname = savedUser.nickname,
            profileImageUrl = savedUser.profileImageUrl,
            isOnline = onlineStatusService.isOnline(savedUser.id)
        )
    }

    fun searchByEmail(email: String): UserResponse {
        val user = userRepository.findByEmail(email)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)

        return UserResponse(
            id = user.id,
            email = user.email,
            nickname = user.nickname,
            profileImageUrl = user.profileImageUrl,
            isOnline = onlineStatusService.isOnline(user.id)
        )
    }
}
