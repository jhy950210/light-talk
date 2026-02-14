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

    // User - Phone
    DUPLICATE_PHONE(HttpStatus.CONFLICT, "U005", "이미 가입된 전화번호입니다"),

    // OTP
    OTP_RATE_LIMIT_EXCEEDED(HttpStatus.TOO_MANY_REQUESTS, "O001", "인증번호 요청이 너무 많습니다. 잠시 후 다시 시도해주세요"),
    OTP_EXPIRED(HttpStatus.BAD_REQUEST, "O002", "인증번호가 만료되었습니다"),
    OTP_INVALID(HttpStatus.BAD_REQUEST, "O003", "인증번호가 올바르지 않습니다"),
    OTP_MAX_ATTEMPTS(HttpStatus.BAD_REQUEST, "O004", "인증번호 입력 횟수를 초과했습니다"),
    VERIFICATION_TOKEN_INVALID(HttpStatus.BAD_REQUEST, "O005", "인증 토큰이 유효하지 않습니다"),

    // Nickname Tag
    NICKNAME_TAG_EXHAUSTED(HttpStatus.CONFLICT, "U006", "해당 닉네임의 태그가 모두 사용되었습니다"),

    // Message
    MESSAGE_NOT_FOUND(HttpStatus.NOT_FOUND, "M001", "메시지를 찾을 수 없습니다"),
    EMPTY_MESSAGE_CONTENT(HttpStatus.BAD_REQUEST, "M002", "메시지 내용이 비어있습니다"),
    MESSAGE_DELETE_FORBIDDEN(HttpStatus.FORBIDDEN, "M003", "본인의 메시지만 삭제할 수 있습니다"),
    MESSAGE_DELETE_EXPIRED(HttpStatus.BAD_REQUEST, "M004", "메시지 삭제 가능 시간(5분)이 지났습니다"),
    MESSAGE_ALREADY_DELETED(HttpStatus.BAD_REQUEST, "M005", "이미 삭제된 메시지입니다"),

    // Group Chat
    GROUP_CHAT_NAME_REQUIRED(HttpStatus.BAD_REQUEST, "GC001", "그룹 채팅방 이름은 필수입니다"),
    GROUP_CHAT_MIN_MEMBERS(HttpStatus.BAD_REQUEST, "GC002", "그룹 채팅방은 최소 2명의 멤버가 필요합니다"),
    GROUP_CHAT_MAX_MEMBERS(HttpStatus.BAD_REQUEST, "GC003", "그룹 채팅방 최대 인원을 초과했습니다"),
    NOT_CHAT_OWNER(HttpStatus.FORBIDDEN, "GC004", "방장 권한이 필요합니다"),
    NOT_CHAT_ADMIN(HttpStatus.FORBIDDEN, "GC005", "관리자 이상의 권한이 필요합니다"),
    CANNOT_LEAVE_DIRECT_CHAT(HttpStatus.BAD_REQUEST, "GC006", "1:1 채팅방에서는 나갈 수 없습니다"),
    CANNOT_MODIFY_DIRECT_CHAT(HttpStatus.BAD_REQUEST, "GC007", "1:1 채팅방은 수정할 수 없습니다"),
    INVALID_ROLE(HttpStatus.BAD_REQUEST, "GC008", "유효하지 않은 역할입니다"),
    CANNOT_CHANGE_OWN_ROLE(HttpStatus.BAD_REQUEST, "GC009", "자신의 역할은 변경할 수 없습니다"),

    // Upload
    INVALID_FILE_TYPE(HttpStatus.BAD_REQUEST, "UP001", "허용되지 않은 파일 형식입니다"),
    FILE_TOO_LARGE(HttpStatus.BAD_REQUEST, "UP002", "파일 크기가 제한을 초과했습니다");
}
