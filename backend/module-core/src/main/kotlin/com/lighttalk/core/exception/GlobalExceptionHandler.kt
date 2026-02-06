package com.lighttalk.core.exception

import com.lighttalk.core.dto.ApiResponse
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.servlet.resource.NoResourceFoundException

@RestControllerAdvice
class GlobalExceptionHandler {

    private val log = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(ApiException::class)
    fun handleApiException(e: ApiException): ResponseEntity<ApiResponse<Nothing>> {
        log.warn("ApiException: code={}, message={}", e.errorCode.code, e.message)
        return ResponseEntity
            .status(e.errorCode.status)
            .body(ApiResponse.error(e.errorCode.code, e.message))
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(e: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Nothing>> {
        val errorMessage = e.bindingResult.fieldErrors
            .joinToString(", ") { "${it.field}: ${it.defaultMessage}" }
        log.warn("Validation failed: {}", errorMessage)
        return ResponseEntity
            .status(ErrorCode.INVALID_INPUT_VALUE.status)
            .body(ApiResponse.error(ErrorCode.INVALID_INPUT_VALUE.code, errorMessage))
    }

    @ExceptionHandler(MissingServletRequestParameterException::class)
    fun handleMissingParam(e: MissingServletRequestParameterException): ResponseEntity<ApiResponse<Nothing>> {
        log.warn("Missing request parameter: {}", e.parameterName)
        return ResponseEntity
            .status(ErrorCode.INVALID_INPUT_VALUE.status)
            .body(ApiResponse.error(ErrorCode.INVALID_INPUT_VALUE.code, "필수 파라미터가 누락되었습니다: ${e.parameterName}"))
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException::class)
    fun handleTypeMismatch(e: MethodArgumentTypeMismatchException): ResponseEntity<ApiResponse<Nothing>> {
        log.warn("Type mismatch: parameter={}, value={}", e.name, e.value)
        return ResponseEntity
            .status(ErrorCode.INVALID_TYPE_VALUE.status)
            .body(ApiResponse.error(ErrorCode.INVALID_TYPE_VALUE.code, "파라미터 타입이 올바르지 않습니다: ${e.name}"))
    }

    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleHttpMessageNotReadable(e: HttpMessageNotReadableException): ResponseEntity<ApiResponse<Nothing>> {
        log.warn("Message not readable: {}", e.message)
        return ResponseEntity
            .status(ErrorCode.INVALID_INPUT_VALUE.status)
            .body(ApiResponse.error(ErrorCode.INVALID_INPUT_VALUE.code, "요청 본문을 읽을 수 없습니다"))
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun handleMethodNotAllowed(e: HttpRequestMethodNotSupportedException): ResponseEntity<ApiResponse<Nothing>> {
        log.warn("Method not allowed: {}", e.method)
        return ResponseEntity
            .status(ErrorCode.METHOD_NOT_ALLOWED.status)
            .body(ApiResponse.error(ErrorCode.METHOD_NOT_ALLOWED.code, ErrorCode.METHOD_NOT_ALLOWED.message))
    }

    @ExceptionHandler(NoResourceFoundException::class)
    fun handleNoResourceFound(e: NoResourceFoundException): ResponseEntity<ApiResponse<Nothing>> {
        log.warn("Resource not found: {}", e.resourcePath)
        return ResponseEntity
            .status(ErrorCode.RESOURCE_NOT_FOUND.status)
            .body(ApiResponse.error(ErrorCode.RESOURCE_NOT_FOUND.code, ErrorCode.RESOURCE_NOT_FOUND.message))
    }

    @ExceptionHandler(Exception::class)
    fun handleException(e: Exception): ResponseEntity<ApiResponse<Nothing>> {
        log.error("Unhandled exception", e)
        return ResponseEntity
            .status(ErrorCode.INTERNAL_SERVER_ERROR.status)
            .body(ApiResponse.error(ErrorCode.INTERNAL_SERVER_ERROR.code, ErrorCode.INTERNAL_SERVER_ERROR.message))
    }
}
