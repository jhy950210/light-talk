package com.lighttalk.auth.sms

import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Service

@Service
@ConditionalOnProperty(name = ["sms.provider"], havingValue = "stub", matchIfMissing = true)
class StubSmsService : SmsService {

    private val log = LoggerFactory.getLogger(StubSmsService::class.java)

    override fun sendOtp(phoneNumber: String, code: String) {
        log.info("[STUB SMS] Sending OTP to {}: code={}", phoneNumber, code)
    }
}
