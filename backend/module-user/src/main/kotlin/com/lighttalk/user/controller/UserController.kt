package com.lighttalk.user.controller

import com.lighttalk.core.dto.ApiResponse
import com.lighttalk.user.dto.UpdateProfileRequest
import com.lighttalk.user.dto.UserResponse
import com.lighttalk.user.dto.WithdrawalRequest
import com.lighttalk.user.service.UserService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

data class UpdateFcmTokenRequest(val fcmToken: String?)

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

    @DeleteMapping("/me")
    fun withdrawUser(
        @AuthenticationPrincipal userId: Long,
        @Valid @RequestBody request: WithdrawalRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        userService.withdrawUser(userId, request.password)
        return ResponseEntity.ok(ApiResponse.success())
    }

    @PutMapping("/me/fcm-token")
    fun updateFcmToken(
        @AuthenticationPrincipal userId: Long,
        @RequestBody request: UpdateFcmTokenRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        userService.updateFcmToken(userId, request.fcmToken)
        return ResponseEntity.ok(ApiResponse.success())
    }

    @GetMapping("/search")
    fun searchUsers(
        @AuthenticationPrincipal userId: Long,
        @RequestParam q: String
    ): ResponseEntity<ApiResponse<List<UserResponse>>> {
        val response = userService.searchUsers(userId, q)
        return ResponseEntity.ok(ApiResponse.success(response))
    }
}
