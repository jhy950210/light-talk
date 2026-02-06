package com.lighttalk.core.dto

import com.fasterxml.jackson.annotation.JsonInclude

@JsonInclude(JsonInclude.Include.NON_NULL)
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: ErrorDetail? = null
) {
    data class ErrorDetail(
        val code: String,
        val message: String
    )

    companion object {
        fun <T> success(data: T): ApiResponse<T> {
            return ApiResponse(success = true, data = data)
        }

        fun success(): ApiResponse<Nothing> {
            return ApiResponse(success = true)
        }

        fun error(code: String, message: String): ApiResponse<Nothing> {
            return ApiResponse(
                success = false,
                error = ErrorDetail(code = code, message = message)
            )
        }
    }
}
