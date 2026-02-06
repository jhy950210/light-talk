package com.lighttalk.core.dto

data class CursorPageRequest(
    val cursor: Long? = null,
    val size: Int = 20
) {
    init {
        require(size in 1..100) { "size must be between 1 and 100" }
    }
}
