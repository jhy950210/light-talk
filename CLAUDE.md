# Light Talk — 프로젝트 가이드

## 개요
가볍고 빠른 실시간 채팅 앱. MVP 단계.

## 기술 스택
- **Backend**: Kotlin + Spring Boot 3, Gradle (Kotlin DSL)
- **Frontend**: Flutter (iOS/Android/Web)
- **DB**: PostgreSQL 16
- **Cache/Pub-Sub**: Redis 7
- **실시간**: WebSocket + STOMP
- **인증**: JWT (Access + Refresh)
- **푸시**: FCM
- **마이그레이션**: Flyway

## 프로젝트 구조
```
light-talk/
├── backend/                    # Spring Boot 멀티모듈
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── module-core/            # 공통 설정, 엔티티, 예외
│   ├── module-auth/            # 인증 (JWT, Spring Security)
│   ├── module-user/            # 유저, 친구, 온라인 상태
│   ├── module-chat/            # 채팅방, WebSocket, 메시지
│   └── module-app/             # 실행 모듈 (main)
├── frontend/                   # Flutter 앱
│   ├── lib/
│   │   ├── core/               # 공통 (theme, constants, dio client)
│   │   ├── features/
│   │   │   ├── auth/           # 로그인/회원가입
│   │   │   ├── friends/        # 친구 목록
│   │   │   └── chat/           # 채팅 목록/방
│   │   └── main.dart
│   └── pubspec.yaml
├── docker-compose.yml
└── CLAUDE.md
```

## DB 스키마
- **users**: id, email, password_hash, nickname, profile_image_url, created_at, updated_at
- **friendships**: id, user_id, friend_id, status(PENDING/ACCEPTED/BLOCKED), created_at
- **chat_rooms**: id, type(DIRECT), created_at
- **chat_members**: id, chat_room_id, user_id, joined_at, last_read_message_id
- **messages**: id, chat_room_id, sender_id, content, type(TEXT/IMAGE/SYSTEM), created_at

## 아키텍처 원칙
- 모듈 간 직접 의존 금지 → 이벤트 또는 Application Service에서 조합
- module-core만 공통 의존 가능
- REST API 경로: `/api/v1/{domain}/...`
- WebSocket 경로: `/ws` (STOMP endpoint)
- STOMP 구독: `/topic/chat/{roomId}`, `/queue/user/{userId}`

## 코딩 컨벤션
- Kotlin: 코루틴 사용 안 함 (일반 Spring MVC), data class 적극 활용
- DTO: Request/Response 분리 (XxxRequest, XxxResponse)
- 예외: 글로벌 @RestControllerAdvice 핸들러
- Flutter: Riverpod + GoRouter, feature-first 구조
