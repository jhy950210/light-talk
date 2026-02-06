package com.lighttalk.user.controller

import com.lighttalk.core.dto.ApiResponse
import com.lighttalk.user.dto.UpdateProfileRequest
import com.lighttalk.user.dto.UserResponse
import com.lighttalk.user.service.UserService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/users")
class UserController(
    private val userService: UserService
) {

    @GetMapping("/me")
    fun getMyProfile(@AuthenticationPrincipal userId: Long): ResponseEntity<ApiResponse<UserResponse>> {
        val response = userService.getProfile(userId)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PutMapping("/me")
    fun updateMyProfile(
        @AuthenticationPrincipal userId: Long,
        @Valid @RequestBody request: UpdateProfileRequest
    ): ResponseEntity<ApiResponse<UserResponse>> {
        val response = userService.updateProfile(userId, request)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @GetMapping("/search")
    fun searchByEmail(
        @AuthenticationPrincipal userId: Long,
        @RequestParam email: String
    ): ResponseEntity<ApiResponse<UserResponse>> {
        val response = userService.searchByEmail(email)
        return ResponseEntity.ok(ApiResponse.success(response))
    }
}
