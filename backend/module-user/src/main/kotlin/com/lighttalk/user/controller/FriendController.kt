package com.lighttalk.user.controller

import com.lighttalk.core.dto.ApiResponse
import com.lighttalk.user.dto.AddFriendRequest
import com.lighttalk.user.dto.FriendResponse
import com.lighttalk.user.service.FriendService
import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/friends")
class FriendController(
    private val friendService: FriendService
) {

    @GetMapping
    fun getFriendList(
        @AuthenticationPrincipal userId: Long
    ): ResponseEntity<ApiResponse<List<FriendResponse>>> {
        val response = friendService.getFriendList(userId)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @PostMapping
    fun addFriend(
        @AuthenticationPrincipal userId: Long,
        @Valid @RequestBody request: AddFriendRequest
    ): ResponseEntity<ApiResponse<FriendResponse>> {
        val response = friendService.addFriend(userId, request.friendId)
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response))
    }

    @PutMapping("/{id}/accept")
    fun acceptFriend(
        @AuthenticationPrincipal userId: Long,
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<FriendResponse>> {
        val response = friendService.acceptFriend(userId, id)
        return ResponseEntity.ok(ApiResponse.success(response))
    }

    @DeleteMapping("/{id}")
    fun removeFriend(
        @AuthenticationPrincipal userId: Long,
        @PathVariable id: Long
    ): ResponseEntity<ApiResponse<Nothing>> {
        friendService.removeFriend(userId, id)
        return ResponseEntity.ok(ApiResponse.success())
    }

    @GetMapping("/pending")
    fun getPendingRequests(
        @AuthenticationPrincipal userId: Long
    ): ResponseEntity<ApiResponse<List<FriendResponse>>> {
        val response = friendService.getPendingRequests(userId)
        return ResponseEntity.ok(ApiResponse.success(response))
    }
}
