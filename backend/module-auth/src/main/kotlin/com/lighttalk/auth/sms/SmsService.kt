package com.lighttalk.auth.sms

interface SmsService {
    fun sendOtp(phoneNumber: String, code: String)
}
