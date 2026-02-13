package com.lighttalk.user.service

import com.lighttalk.core.entity.Friendship
import com.lighttalk.core.entity.FriendshipStatus
import com.lighttalk.core.exception.ApiException
import com.lighttalk.core.exception.ErrorCode
import com.lighttalk.user.dto.FriendResponse
import com.lighttalk.user.repository.FriendshipRepository
import com.lighttalk.user.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class FriendService(
    private val friendshipRepository: FriendshipRepository,
    private val userRepository: UserRepository,
    private val onlineStatusService: OnlineStatusService
) {

    @Transactional
    fun addFriend(userId: Long, friendId: Long): FriendResponse {
        val friend = userRepository.findById(friendId)
            .orElseThrow { ApiException(ErrorCode.USER_NOT_FOUND) }

        if (friend.id == userId) {
            throw ApiException(ErrorCode.SELF_FRIEND_REQUEST)
        }

        val existingFriendship = friendshipRepository.findByUserIdAndFriendId(userId, friend.id)
        if (existingFriendship != null) {
            when (existingFriendship.status) {
                FriendshipStatus.ACCEPTED -> throw ApiException(ErrorCode.ALREADY_FRIENDS)
                FriendshipStatus.PENDING -> throw ApiException(ErrorCode.FRIEND_REQUEST_ALREADY_SENT)
                FriendshipStatus.BLOCKED -> throw ApiException(ErrorCode.ACCESS_DENIED)
            }
        }

        val reverseFriendship = friendshipRepository.findByUserIdAndFriendId(friend.id, userId)
        if (reverseFriendship != null && reverseFriendship.status == FriendshipStatus.PENDING) {
            reverseFriendship.status = FriendshipStatus.ACCEPTED
            friendshipRepository.save(reverseFriendship)

            val mutualFriendship = Friendship(
                userId = userId,
                friendId = friend.id,
                status = FriendshipStatus.ACCEPTED
            )
            friendshipRepository.save(mutualFriendship)

            return FriendResponse(
                id = friend.id,
                nickname = friend.nickname,
                tag = friend.tag,
                profileImageUrl = friend.profileImageUrl,
                isOnline = onlineStatusService.isOnline(friend.id)
            )
        }

        val friendship = Friendship(
            userId = userId,
            friendId = friend.id,
            status = FriendshipStatus.PENDING
        )
        friendshipRepository.save(friendship)

        return FriendResponse(
            id = friend.id,
            nickname = friend.nickname,
            tag = friend.tag,
            profileImageUrl = friend.profileImageUrl,
            isOnline = onlineStatusService.isOnline(friend.id)
        )
    }

    @Transactional
    fun acceptFriend(userId: Long, friendshipId: Long): FriendResponse {
        val friendship = friendshipRepository.findById(friendshipId)
            .orElseThrow { ApiException(ErrorCode.FRIEND_REQUEST_NOT_FOUND) }

        if (friendship.friendId != userId) {
            throw ApiException(ErrorCode.ACCESS_DENIED)
        }

        if (friendship.status != FriendshipStatus.PENDING) {
            throw ApiException(ErrorCode.FRIEND_REQUEST_NOT_FOUND)
        }

        friendship.status = FriendshipStatus.ACCEPTED
        friendshipRepository.save(friendship)

        val mutualFriendship = friendshipRepository.findByUserIdAndFriendId(userId, friendship.userId)
        if (mutualFriendship == null) {
            val reverseFriendship = Friendship(
                userId = userId,
                friendId = friendship.userId,
                status = FriendshipStatus.ACCEPTED
            )
            friendshipRepository.save(reverseFriendship)
        } else {
            mutualFriendship.status = FriendshipStatus.ACCEPTED
            friendshipRepository.save(mutualFriendship)
        }

        val friend = userRepository.findById(friendship.userId)
            .orElseThrow { ApiException(ErrorCode.USER_NOT_FOUND) }

        return FriendResponse(
            id = friend.id,
            nickname = friend.nickname,
            tag = friend.tag,
            profileImageUrl = friend.profileImageUrl,
            isOnline = onlineStatusService.isOnline(friend.id)
        )
    }

    @Transactional
    fun blockFriend(userId: Long, friendshipId: Long) {
        val friendship = friendshipRepository.findById(friendshipId)
            .orElseThrow { ApiException(ErrorCode.FRIEND_REQUEST_NOT_FOUND) }

        if (friendship.userId != userId && friendship.friendId != userId) {
            throw ApiException(ErrorCode.ACCESS_DENIED)
        }

        friendship.status = FriendshipStatus.BLOCKED
        friendshipRepository.save(friendship)
    }

    @Transactional
    fun removeFriend(userId: Long, friendshipId: Long) {
        val friendship = friendshipRepository.findById(friendshipId)
            .orElseThrow { ApiException(ErrorCode.FRIEND_REQUEST_NOT_FOUND) }

        if (friendship.userId != userId && friendship.friendId != userId) {
            throw ApiException(ErrorCode.ACCESS_DENIED)
        }

        val friendId = if (friendship.userId == userId) friendship.friendId else friendship.userId

        friendshipRepository.delete(friendship)

        val reverseFriendship = friendshipRepository.findByUserIdAndFriendId(friendId, userId)
        if (reverseFriendship != null) {
            friendshipRepository.delete(reverseFriendship)
        }
    }

    fun getFriendList(userId: Long): List<FriendResponse> {
        val friendships = friendshipRepository.findByUserIdAndStatus(userId, FriendshipStatus.ACCEPTED)
        val friendIds = friendships.map { it.friendId }

        if (friendIds.isEmpty()) return emptyList()

        val friends = userRepository.findAllById(friendIds)
        val onlineUserIds = onlineStatusService.getOnlineUserIds(friendIds)

        return friends.map { friend ->
            FriendResponse(
                id = friend.id,
                nickname = friend.nickname,
                tag = friend.tag,
                profileImageUrl = friend.profileImageUrl,
                isOnline = onlineUserIds.contains(friend.id)
            )
        }
    }

    fun getPendingRequests(userId: Long): List<FriendResponse> {
        val pendingFriendships = friendshipRepository.findByFriendIdAndStatus(userId, FriendshipStatus.PENDING)
        val requesterIds = pendingFriendships.map { it.userId }

        if (requesterIds.isEmpty()) return emptyList()

        val requesters = userRepository.findAllById(requesterIds)
        val onlineUserIds = onlineStatusService.getOnlineUserIds(requesterIds)
        val friendshipByUserId = pendingFriendships.associateBy { it.userId }

        return requesters.map { requester ->
            FriendResponse(
                id = requester.id,
                nickname = requester.nickname,
                tag = requester.tag,
                profileImageUrl = requester.profileImageUrl,
                isOnline = onlineUserIds.contains(requester.id),
                friendshipId = friendshipByUserId[requester.id]?.id
            )
        }
    }
}
