package com.lighttalk.auth.sms

import com.lighttalk.auth.config.SmsProperties
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Service
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

@Service
@ConditionalOnProperty(name = ["sms.provider"], havingValue = "naver")
class NaverSensService(
    private val smsProperties: SmsProperties
) : SmsService {

    private val log = LoggerFactory.getLogger(NaverSensService::class.java)
    private val httpClient = HttpClient.newHttpClient()

    override fun sendOtp(phoneNumber: String, code: String) {
        val naver = smsProperties.naver
        val timestamp = System.currentTimeMillis().toString()
        val url = "/sms/v2/services/${naver.serviceId}/messages"
        val signature = makeSignature("POST", url, timestamp, naver.accessKey, naver.secretKey)

        val body = """
            {
                "type": "SMS",
                "from": "${naver.callingNumber}",
                "content": "Light Talk 인증번호: $code",
                "messages": [{"to": "$phoneNumber"}]
            }
        """.trimIndent()

        val request = HttpRequest.newBuilder()
            .uri(URI.create("https://sens.apigw.ntruss.com$url"))
            .header("Content-Type", "application/json; charset=utf-8")
            .header("x-ncp-apigw-timestamp", timestamp)
            .header("x-ncp-iam-access-key", naver.accessKey)
            .header("x-ncp-apigw-signature-v2", signature)
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())

        if (response.statusCode() !in 200..299) {
            log.error("Naver SENS SMS failed: status={}, body={}", response.statusCode(), response.body())
            throw RuntimeException("SMS 전송에 실패했습니다")
        }

        log.info("Naver SENS SMS sent to {}", phoneNumber)
    }

    private fun makeSignature(
        method: String,
        url: String,
        timestamp: String,
        accessKey: String,
        secretKey: String
    ): String {
        val message = "$method $url\n$timestamp\n$accessKey"
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(secretKey.toByteArray(Charsets.UTF_8), "HmacSHA256"))
        val rawHmac = mac.doFinal(message.toByteArray(Charsets.UTF_8))
        return Base64.getEncoder().encodeToString(rawHmac)
    }
}
