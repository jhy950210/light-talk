package com.lighttalk.auth.service

import com.lighttalk.auth.config.BlindIndexProperties
import org.springframework.stereotype.Service
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

@Service
class BlindIndexService(private val properties: BlindIndexProperties) {

    fun generate(rawValue: String): String {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(properties.secretKey.toByteArray(), "HmacSHA256"))
        return mac.doFinal(rawValue.toByteArray()).joinToString("") { "%02x".format(it) }
    }
}
