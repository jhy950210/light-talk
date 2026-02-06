package com.lighttalk.auth.service

import com.lighttalk.auth.dto.LoginRequest
import com.lighttalk.auth.dto.RegisterRequest
import com.lighttalk.auth.dto.TokenResponse
import com.lighttalk.auth.jwt.JwtTokenProvider
import com.lighttalk.auth.repository.AuthUserRepository
import com.lighttalk.core.entity.User
import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class AuthService(
    private val authUserRepository: AuthUserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtTokenProvider: JwtTokenProvider
) {

    @Transactional
    fun register(request: RegisterRequest): TokenResponse {
        if (authUserRepository.existsByEmail(request.email)) {
            throw ApiException(ErrorCode.DUPLICATE_EMAIL)
        }

        val user = User(
            email = request.email,
            passwordHash = passwordEncoder.encode(request.password),
            nickname = request.nickname
        )

        val savedUser = authUserRepository.save(user)

        return generateTokenResponse(savedUser.id)
    }

    fun login(request: LoginRequest): TokenResponse {
        val user = authUserRepository.findByEmail(request.email)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)

        if (!passwordEncoder.matches(request.password, user.passwordHash)) {
            throw ApiException(ErrorCode.INVALID_PASSWORD)
        }

        return generateTokenResponse(user.id)
    }

    fun refreshToken(refreshToken: String): TokenResponse {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw ApiException(ErrorCode.INVALID_TOKEN)
        }

        if (!jwtTokenProvider.isRefreshToken(refreshToken)) {
            throw ApiException(ErrorCode.INVALID_TOKEN)
        }

        val userId = jwtTokenProvider.extractUserId(refreshToken)

        if (!authUserRepository.existsById(userId)) {
            throw ApiException(ErrorCode.USER_NOT_FOUND)
        }

        return generateTokenResponse(userId)
    }

    private fun generateTokenResponse(userId: Long): TokenResponse {
        val accessToken = jwtTokenProvider.generateAccessToken(userId)
        val refreshToken = jwtTokenProvider.generateRefreshToken(userId)

        return TokenResponse(
            accessToken = accessToken,
            refreshToken = refreshToken,
            expiresIn = jwtTokenProvider.getAccessTokenExpiry()
        )
    }
}
