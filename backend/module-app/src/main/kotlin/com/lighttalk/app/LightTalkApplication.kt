package com.lighttalk.app

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.autoconfigure.domain.EntityScan
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication
import org.springframework.data.jpa.repository.config.EnableJpaRepositories
import org.springframework.scheduling.annotation.EnableAsync

@SpringBootApplication(scanBasePackages = ["com.lighttalk"])
@EntityScan(basePackages = ["com.lighttalk"])
@EnableJpaRepositories(basePackages = ["com.lighttalk"])
@ConfigurationPropertiesScan(basePackages = ["com.lighttalk"])
@EnableAsync
class LightTalkApplication

fun main(args: Array<String>) {
    runApplication<LightTalkApplication>(*args)
}
