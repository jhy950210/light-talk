package com.lighttalk.auth.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "blind-index")
data class BlindIndexProperties(
    val secretKey: String = "light-talk-blind-index-secret-key-change-in-production"
)
