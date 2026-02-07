package com.lighttalk.auth.service

import com.lighttalk.auth.sms.SmsService
import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import org.springframework.data.redis.core.RedisTemplate
import org.springframework.stereotype.Service
import java.time.Duration
import java.util.Random
import java.util.UUID
import java.util.concurrent.TimeUnit

@Service
class OtpService(
    private val redisTemplate: RedisTemplate<String, String>,
    private val smsService: SmsService,
    private val blindIndexService: BlindIndexService
) {

    fun sendOtp(phoneNumber: String): Int {
        val phoneHash = blindIndexService.generate(phoneNumber)

        // Rate limit check
        val rateKey = "otp_rate:$phoneHash"
        val count = redisTemplate.opsForValue().increment(rateKey) ?: 1
        if (count == 1L) {
            redisTemplate.expire(rateKey, Duration.ofHours(1))
        }
        if (count > 5) {
            throw ApiException(ErrorCode.OTP_RATE_LIMIT_EXCEEDED)
        }

        val code = String.format("%06d", Random().nextInt(1000000))
        val otpKey = "otp:$phoneHash"
        redisTemplate.opsForValue().set(otpKey, "$code:0", Duration.ofMinutes(5))

        smsService.sendOtp(phoneNumber, code)

        return 300 // 5 minutes in seconds
    }

    fun verifyOtp(phoneNumber: String, code: String): String {
        val phoneHash = blindIndexService.generate(phoneNumber)
        val otpKey = "otp:$phoneHash"
        val stored = redisTemplate.opsForValue().get(otpKey)
            ?: throw ApiException(ErrorCode.OTP_EXPIRED)

        val parts = stored.split(":")
        val storedCode = parts[0]
        val attempts = parts[1].toInt()

        if (attempts >= 3) {
            redisTemplate.delete(otpKey)
            throw ApiException(ErrorCode.OTP_MAX_ATTEMPTS)
        }

        if (code != storedCode) {
            val remainingTtl = redisTemplate.getExpire(otpKey, TimeUnit.SECONDS)
            if (remainingTtl > 0) {
                redisTemplate.opsForValue().set(otpKey, "$storedCode:${attempts + 1}", Duration.ofSeconds(remainingTtl))
            }
            throw ApiException(ErrorCode.OTP_INVALID)
        }

        redisTemplate.delete(otpKey)

        val token = UUID.randomUUID().toString()
        redisTemplate.opsForValue().set("otp_verified:$token", phoneHash, Duration.ofMinutes(10))

        return token
    }

    fun consumeVerificationToken(token: String): String {
        val key = "otp_verified:$token"
        val phoneHash = redisTemplate.opsForValue().get(key)
            ?: throw ApiException(ErrorCode.VERIFICATION_TOKEN_INVALID)
        redisTemplate.delete(key)
        return phoneHash
    }
}
