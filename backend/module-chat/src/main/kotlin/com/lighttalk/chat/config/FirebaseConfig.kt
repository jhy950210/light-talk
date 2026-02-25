package com.lighttalk.chat.config

import com.google.auth.oauth2.GoogleCredentials
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.context.annotation.Configuration
import jakarta.annotation.PostConstruct
import java.io.ByteArrayInputStream

@Configuration
@ConditionalOnProperty(
    name = ["push.notification.provider"],
    havingValue = "fcm"
)
class FirebaseConfig(
    @Value("\${firebase.credentials-json:}") private val credentialsJson: String
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @PostConstruct
    fun initialize() {
        if (FirebaseApp.getApps().isNotEmpty()) {
            log.info("Firebase already initialized")
            return
        }

        val credentials = if (credentialsJson.isNotBlank()) {
            GoogleCredentials.fromStream(ByteArrayInputStream(credentialsJson.toByteArray()))
        } else {
            // Falls back to GOOGLE_APPLICATION_CREDENTIALS env var
            GoogleCredentials.getApplicationDefault()
        }

        val options = FirebaseOptions.builder()
            .setCredentials(credentials)
            .build()

        FirebaseApp.initializeApp(options)
        log.info("Firebase initialized successfully")
    }
}
