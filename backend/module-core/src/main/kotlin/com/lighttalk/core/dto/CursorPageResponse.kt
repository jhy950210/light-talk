package com.lighttalk.core.dto

data class CursorPageResponse<T>(
    val content: List<T>,
    val hasMore: Boolean,
    val nextCursor: Long?
)
