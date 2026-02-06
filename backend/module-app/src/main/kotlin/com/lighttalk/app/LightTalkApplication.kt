package com.lighttalk.app

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication(scanBasePackages = ["com.lighttalk"])
class LightTalkApplication

fun main(args: Array<String>) {
    runApplication<LightTalkApplication>(*args)
}
