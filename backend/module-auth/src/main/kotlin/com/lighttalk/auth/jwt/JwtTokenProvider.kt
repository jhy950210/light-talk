package com.lighttalk.auth.jwt

import com.lighttalk.auth.config.JwtProperties
import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import io.jsonwebtoken.Claims
import io.jsonwebtoken.ExpiredJwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.stereotype.Component
import java.util.Date
import javax.crypto.SecretKey

@Component
class JwtTokenProvider(
    private val jwtProperties: JwtProperties
) {

    private val secretKey: SecretKey by lazy {
        Keys.hmacShaKeyFor(jwtProperties.secret.toByteArray())
    }

    fun generateAccessToken(userId: Long): String {
        return generateToken(userId, jwtProperties.accessTokenExpiry, "access")
    }

    fun generateRefreshToken(userId: Long): String {
        return generateToken(userId, jwtProperties.refreshTokenExpiry, "refresh")
    }

    private fun generateToken(userId: Long, expiryMs: Long, tokenType: String): String {
        val now = Date()
        val expiry = Date(now.time + expiryMs)

        return Jwts.builder()
            .subject(userId.toString())
            .claim("type", tokenType)
            .issuedAt(now)
            .expiration(expiry)
            .signWith(secretKey)
            .compact()
    }

    fun validateToken(token: String): Boolean {
        return try {
            parseClaims(token)
            true
        } catch (e: ExpiredJwtException) {
            false
        } catch (e: Exception) {
            false
        }
    }

    fun extractUserId(token: String): Long {
        val claims = parseClaims(token)
        return claims.subject.toLong()
    }

    fun validateAndExtractUserId(token: String): Long {
        return try {
            val claims = parseClaims(token)
            claims.subject.toLong()
        } catch (e: ExpiredJwtException) {
            throw ApiException(ErrorCode.EXPIRED_TOKEN)
        } catch (e: Exception) {
            throw ApiException(ErrorCode.INVALID_TOKEN)
        }
    }

    fun isRefreshToken(token: String): Boolean {
        return try {
            val claims = parseClaims(token)
            claims["type"] == "refresh"
        } catch (e: Exception) {
            false
        }
    }

    fun getAccessTokenExpiry(): Long {
        return jwtProperties.accessTokenExpiry
    }

    private fun parseClaims(token: String): Claims {
        return Jwts.parser()
            .verifyWith(secretKey)
            .build()
            .parseSignedClaims(token)
            .payload
    }
}
