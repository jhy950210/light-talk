package com.lighttalk.app.storage

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "storage.r2")
data class R2StorageProperties(
    val endpoint: String = "",
    val bucket: String = "lighttalk-media",
    val accessKey: String = "",
    val secretKey: String = "",
    val publicUrl: String = ""
)
