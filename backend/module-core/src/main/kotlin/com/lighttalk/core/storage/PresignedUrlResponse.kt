package com.lighttalk.core.storage

data class PresignedUrlResponse(
    val uploadUrl: String,
    val publicUrl: String
)
