package com.lighttalk.auth.controller

import com.lighttalk.auth.dto.LoginRequest
import com.lighttalk.auth.dto.RefreshRequest
import com.lighttalk.auth.dto.RegisterRequest
import com.lighttalk.auth.dto.TokenResponse
import com.lighttalk.auth.service.AuthService
import com.lighttalk.core.dto.ApiResponse
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/auth")
class AuthController(
    private val authService: AuthService
) {

    @PostMapping("/register")
    fun register(@Valid @RequestBody request: RegisterRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        val response = authService.register(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response))
    }

    @PostMapping("/login")
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        val response = authService.login(request)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PostMapping("/refresh")
    fun refresh(@Valid @RequestBody request: RefreshRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        val response = authService.refreshToken(request.refreshToken)
        return ResponseEntity.ok(ApiResponse.success(response))
    }
}
