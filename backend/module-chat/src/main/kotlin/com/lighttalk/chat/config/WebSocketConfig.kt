package com.lighttalk.chat.config

import org.springframework.context.annotation.Configuration
import org.springframework.messaging.simp.config.ChannelRegistration
import org.springframework.messaging.simp.config.MessageBrokerRegistry
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker
import org.springframework.web.socket.config.annotation.StompEndpointRegistry
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer
import org.springframework.web.socket.config.annotation.WebSocketTransportRegistration

@Configuration
@EnableWebSocketMessageBroker
class WebSocketConfig(
    private val webSocketAuthInterceptor: WebSocketAuthInterceptor
) : WebSocketMessageBrokerConfigurer {

    override fun registerStompEndpoints(registry: StompEndpointRegistry) {
        // SockJS endpoint for web clients
        registry.addEndpoint("/ws")
            .setAllowedOriginPatterns("*")
            .withSockJS()
            .setTaskScheduler(sockJsTaskScheduler())

        // Raw WebSocket endpoint for mobile clients
        registry.addEndpoint("/ws/raw")
            .setAllowedOriginPatterns("*")
    }

    override fun configureMessageBroker(registry: MessageBrokerRegistry) {
        val heartbeatScheduler = ThreadPoolTaskScheduler()
        heartbeatScheduler.poolSize = 1
        heartbeatScheduler.setThreadNamePrefix("ws-heartbeat-")
        heartbeatScheduler.initialize()

        registry.enableSimpleBroker("/topic", "/queue")
            .setHeartbeatValue(longArrayOf(25000, 25000))
            .setTaskScheduler(heartbeatScheduler)
        registry.setApplicationDestinationPrefixes("/app")
        registry.setUserDestinationPrefix("/user")
    }

    override fun configureWebSocketTransport(registration: WebSocketTransportRegistration) {
        registration.setSendTimeLimit(15 * 1000)
        registration.setSendBufferSizeLimit(512 * 1024)
        registration.setMessageSizeLimit(128 * 1024)
    }

    override fun configureClientInboundChannel(registration: ChannelRegistration) {
        registration.interceptors(webSocketAuthInterceptor)
    }

    private fun sockJsTaskScheduler(): ThreadPoolTaskScheduler {
        val scheduler = ThreadPoolTaskScheduler()
        scheduler.poolSize = 2
        scheduler.setThreadNamePrefix("sockjs-")
        scheduler.initialize()
        return scheduler
    }
}
