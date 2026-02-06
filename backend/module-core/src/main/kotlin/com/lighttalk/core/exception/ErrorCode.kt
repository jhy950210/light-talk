package com.lighttalk.core.exception

import org.springframework.http.HttpStatus

enum class ErrorCode(
    val status: HttpStatus,
    val code: String,
    val message: String
) {
    // Common
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "C001", "서버 내부 오류가 발생했습니다"),
    INVALID_INPUT_VALUE(HttpStatus.BAD_REQUEST, "C002", "잘못된 입력값입니다"),
    METHOD_NOT_ALLOWED(HttpStatus.METHOD_NOT_ALLOWED, "C003", "허용되지 않은 HTTP 메서드입니다"),
    RESOURCE_NOT_FOUND(HttpStatus.NOT_FOUND, "C004", "리소스를 찾을 수 없습니다"),
    INVALID_TYPE_VALUE(HttpStatus.BAD_REQUEST, "C005", "잘못된 타입입니다"),

    // Auth
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "A001", "인증이 필요합니다"),
    ACCESS_DENIED(HttpStatus.FORBIDDEN, "A002", "접근 권한이 없습니다"),
    INVALID_TOKEN(HttpStatus.UNAUTHORIZED, "A003", "유효하지 않은 토큰입니다"),
    EXPIRED_TOKEN(HttpStatus.UNAUTHORIZED, "A004", "만료된 토큰입니다"),

    // User
    USER_NOT_FOUND(HttpStatus.NOT_FOUND, "U001", "사용자를 찾을 수 없습니다"),
    DUPLICATE_EMAIL(HttpStatus.CONFLICT, "U002", "이미 사용 중인 이메일입니다"),
    DUPLICATE_NICKNAME(HttpStatus.CONFLICT, "U003", "이미 사용 중인 닉네임입니다"),
    INVALID_PASSWORD(HttpStatus.BAD_REQUEST, "U004", "비밀번호가 올바르지 않습니다"),

    // Friend
    FRIEND_REQUEST_NOT_FOUND(HttpStatus.NOT_FOUND, "F001", "친구 요청을 찾을 수 없습니다"),
    ALREADY_FRIENDS(HttpStatus.CONFLICT, "F002", "이미 친구 관계입니다"),
    SELF_FRIEND_REQUEST(HttpStatus.BAD_REQUEST, "F003", "자기 자신에게 친구 요청을 보낼 수 없습니다"),
    FRIEND_REQUEST_ALREADY_SENT(HttpStatus.CONFLICT, "F004", "이미 친구 요청을 보냈습니다"),

    // Chat
    CHAT_ROOM_NOT_FOUND(HttpStatus.NOT_FOUND, "CH001", "채팅방을 찾을 수 없습니다"),
    NOT_CHAT_MEMBER(HttpStatus.FORBIDDEN, "CH002", "채팅방 멤버가 아닙니다"),
    CHAT_ROOM_ALREADY_EXISTS(HttpStatus.CONFLICT, "CH003", "이미 존재하는 채팅방입니다"),

    // Message
    MESSAGE_NOT_FOUND(HttpStatus.NOT_FOUND, "M001", "메시지를 찾을 수 없습니다"),
    EMPTY_MESSAGE_CONTENT(HttpStatus.BAD_REQUEST, "M002", "메시지 내용이 비어있습니다");
}
