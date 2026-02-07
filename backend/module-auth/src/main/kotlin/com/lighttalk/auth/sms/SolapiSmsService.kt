package com.lighttalk.auth.sms

import com.lighttalk.auth.config.SmsProperties
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Service
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.ZoneOffset
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

@Service
@ConditionalOnProperty(name = ["sms.provider"], havingValue = "solapi")
class SolapiSmsService(
    private val smsProperties: SmsProperties
) : SmsService {

    private val log = LoggerFactory.getLogger(SolapiSmsService::class.java)
    private val httpClient = HttpClient.newHttpClient()

    override fun sendOtp(phoneNumber: String, code: String) {
        val solapi = smsProperties.solapi
        val dateTime = ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT)
        val salt = UUID.randomUUID().toString().replace("-", "").take(32)
        val signature = makeSignature(dateTime, salt, solapi.apiSecret)

        val body = """
            {
                "messages": [
                    {
                        "to": "$phoneNumber",
                        "from": "${solapi.callingNumber}",
                        "text": "[Light Talk] 인증번호: $code",
                        "type": "SMS"
                    }
                ]
            }
        """.trimIndent()

        val request = HttpRequest.newBuilder()
            .uri(URI.create("https://api.solapi.com/messages/v4/send-many/detail"))
            .header("Content-Type", "application/json; charset=utf-8")
            .header("Authorization", "HMAC-SHA256 apiKey=${solapi.apiKey}, date=$dateTime, salt=$salt, signature=$signature")
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())

        if (response.statusCode() !in 200..299) {
            log.error("Solapi SMS failed: status={}, body={}", response.statusCode(), response.body())
            throw RuntimeException("SMS 전송에 실패했습니다")
        }

        log.info("Solapi SMS sent to {}", phoneNumber)
    }

    private fun makeSignature(dateTime: String, salt: String, apiSecret: String): String {
        val data = dateTime + salt
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(apiSecret.toByteArray(Charsets.UTF_8), "HmacSHA256"))
        val rawHmac = mac.doFinal(data.toByteArray(Charsets.UTF_8))
        return rawHmac.joinToString("") { "%02x".format(it) }
    }
}
