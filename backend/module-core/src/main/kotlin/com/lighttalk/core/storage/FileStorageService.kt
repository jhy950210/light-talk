package com.lighttalk.core.storage

interface FileStorageService {
    fun generatePresignedUploadUrl(path: String, contentType: String, contentLength: Long): PresignedUrlResponse
    fun delete(path: String)
}
