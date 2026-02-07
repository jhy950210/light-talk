package com.lighttalk.auth.controller

import com.lighttalk.auth.dto.PhoneLoginRequest
import com.lighttalk.auth.dto.PhoneRegisterRequest
import com.lighttalk.auth.dto.RefreshRequest
import com.lighttalk.auth.dto.SendOtpRequest
import com.lighttalk.auth.dto.SendOtpResponse
import com.lighttalk.auth.dto.TokenResponse
import com.lighttalk.auth.dto.VerifyOtpRequest
import com.lighttalk.auth.dto.VerifyOtpResponse
import com.lighttalk.auth.service.AuthService
import com.lighttalk.auth.service.OtpService
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
    private val authService: AuthService,
    private val otpService: OtpService
) {

    @PostMapping("/refresh")
    fun refresh(@Valid @RequestBody request: RefreshRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        val response = authService.refreshToken(request.refreshToken)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PostMapping("/send-otp")
    fun sendOtp(@Valid @RequestBody request: SendOtpRequest): ResponseEntity<ApiResponse<SendOtpResponse>> {
        val expiresIn = otpService.sendOtp(request.phoneNumber)
        return ResponseEntity.ok(ApiResponse.success(SendOtpResponse(expiresIn = expiresIn)))
    }

    @PostMapping("/verify-otp")
    fun verifyOtp(@Valid @RequestBody request: VerifyOtpRequest): ResponseEntity<ApiResponse<VerifyOtpResponse>> {
        val response = authService.verifyOtp(request)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PostMapping("/phone/register")
    fun phoneRegister(@Valid @RequestBody request: PhoneRegisterRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        val response = authService.phoneRegister(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response))
    }

    @PostMapping("/phone/login")
    fun phoneLogin(@Valid @RequestBody request: PhoneLoginRequest): ResponseEntity<ApiResponse<TokenResponse>> {
        val response = authService.phoneLogin(request)
        return ResponseEntity.ok(ApiResponse.success(response))
    }
}
