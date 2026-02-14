package com.lighttalk.auth.jwt

import com.lighttalk.core.auth.TokenValidator
import org.springframework.stereotype.Component

@Component
class JwtTokenValidator(
    private val jwtTokenProvider: JwtTokenProvider
) : TokenValidator {

    override fun validateAndExtractUserId(token: String): Long {
        return jwtTokenProvider.validateAndExtractUserId(token)
    }
}
