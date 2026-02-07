package com.lighttalk.auth.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "sms")
data class SmsProperties(
    val provider: String = "stub",
    val naver: NaverSensProperties = NaverSensProperties(),
    val solapi: SolapiProperties = SolapiProperties()
) {
    data class NaverSensProperties(
        val serviceId: String = "",
        val accessKey: String = "",
        val secretKey: String = "",
        val callingNumber: String = ""
    )

    data class SolapiProperties(
        val apiKey: String = "",
        val apiSecret: String = "",
        val callingNumber: String = ""
    )
}
