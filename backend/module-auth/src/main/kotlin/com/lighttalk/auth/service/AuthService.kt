package com.lighttalk.auth.service

import com.lighttalk.auth.dto.PhoneLoginRequest
import com.lighttalk.auth.dto.PhoneRegisterRequest
import com.lighttalk.auth.dto.TokenResponse
import com.lighttalk.auth.dto.VerifyOtpRequest
import com.lighttalk.auth.dto.VerifyOtpResponse
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
    private val jwtTokenProvider: JwtTokenProvider,
    private val otpService: OtpService,
    private val blindIndexService: BlindIndexService
) {

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

    // --- Phone-based authentication ---

    fun verifyOtp(request: VerifyOtpRequest): VerifyOtpResponse {
        val token = otpService.verifyOtp(request.phoneNumber, request.code)
        val phoneHash = blindIndexService.generate(request.phoneNumber)
        val isNewUser = !authUserRepository.existsByPhoneBlindIndex(phoneHash)
        return VerifyOtpResponse(verificationToken = token, isNewUser = isNewUser)
    }

    @Transactional
    fun phoneRegister(request: PhoneRegisterRequest): TokenResponse {
        val phoneHash = otpService.consumeVerificationToken(request.verificationToken)

        if (authUserRepository.existsByPhoneBlindIndex(phoneHash)) {
            throw ApiException(ErrorCode.DUPLICATE_PHONE)
        }

        val tag = generateTag(request.nickname)

        val user = User(
            phoneBlindIndex = phoneHash,
            passwordHash = passwordEncoder.encode(request.password),
            nickname = request.nickname,
            tag = tag
        )

        val savedUser = authUserRepository.save(user)

        return generateTokenResponse(savedUser.id)
    }

    fun phoneLogin(request: PhoneLoginRequest): TokenResponse {
        val phoneHash = blindIndexService.generate(request.phoneNumber)
        val user = authUserRepository.findByPhoneBlindIndex(phoneHash)
            ?: throw ApiException(ErrorCode.USER_NOT_FOUND)

        if (!passwordEncoder.matches(request.password, user.passwordHash)) {
            throw ApiException(ErrorCode.INVALID_PASSWORD)
        }

        return generateTokenResponse(user.id)
    }

    private fun generateTag(nickname: String): String {
        val maxTag = authUserRepository.findMaxTagByNickname(nickname) ?: 0
        val nextTag = maxTag + 1
        if (nextTag > 9999) throw ApiException(ErrorCode.NICKNAME_TAG_EXHAUSTED)
        return String.format("%04d", nextTag)
    }

    private fun generateTokenResponse(userId: Long): TokenResponse {
        val accessToken = jwtTokenProvider.generateAccessToken(userId)
        val refreshToken = jwtTokenProvider.generateRefreshToken(userId)

        val user = authUserRepository.findById(userId).orElseThrow { ApiException(ErrorCode.USER_NOT_FOUND) }

        return TokenResponse(
            accessToken = accessToken,
            refreshToken = refreshToken,
            expiresIn = jwtTokenProvider.getAccessTokenExpiry(),
            userId = userId,
            nickname = user.nickname,
            tag = user.tag
        )
    }
}
