package com.lighttalk.core.auth

interface TokenValidator {
    fun validateAndExtractUserId(token: String): Long
}
