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

## 인증 방식
- **Phone-First**: 전화번호 SMS OTP → 비밀번호 설정 (Solapi/CoolSMS, ~18원/건)
- **Blind Index**: HMAC-SHA256(secret_key, phone_number) 저장, 원본 전화번호 미저장
- **OTP**: Redis에 5분 TTL, 3회 입력 제한, 시간당 5회 요청 제한
- **디바이스 키**: (Phase 2) 가입 시 1회 SMS, 이후 디바이스 바운드 키로 로그인

## 닉네임#태그 시스템
- **Discord 스타일**: 닉네임 뒤에 자동 생성된 4자리 태그 (예: 테스터#0001)
- **유니크 제약**: (nickname, tag) 쌍으로 유일, 같은 닉네임이라도 태그로 구분
- **태그 자동 할당**: 가입 시 해당 닉네임의 최대 태그+1을 순차 할당 (0001~9999)
- **친구 검색**: 닉네임 부분 검색 (리스트 반환) 또는 닉네임#태그 정확 검색 (단일 반환)
- **친구 추가**: userId 기반 (이메일 필드 완전 제거됨)

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
│   │   │   ├── auth/           # 전화번호 인증/로그인/회원가입
│   │   │   ├── friends/        # 친구 목록
│   │   │   └── chat/           # 채팅 목록/방
│   │   └── main.dart
│   └── pubspec.yaml
├── docker-compose.yml
└── CLAUDE.md
```

## DB 스키마
- **users**: id, phone_blind_index, password_hash, nickname, tag(VARCHAR 4), profile_image_url, created_at, updated_at — UNIQUE(nickname, tag)
- **otp_verifications**: id, phone_blind_index, otp_code, attempts, expires_at, verified, created_at
- **friendships**: id, user_id, friend_id, status(PENDING/ACCEPTED/BLOCKED), created_at
- **chat_rooms**: id, type(DIRECT), created_at
- **chat_members**: id, chat_room_id, user_id, joined_at, last_read_message_id
- **messages**: id, chat_room_id, sender_id, content, type(TEXT/IMAGE/VIDEO/SYSTEM), created_at, deleted_at

## 아키텍처 원칙
- 모듈 간 직접 의존 금지 → 이벤트 또는 Application Service에서 조합
- module-core만 공통 의존 가능
- REST API 경로: `/api/v1/{domain}/...`
- WebSocket 경로: `/ws` (STOMP endpoint)
- STOMP 구독: `/topic/chat/{roomId}`, `/queue/user/{userId}`

## API 엔드포인트 (정본)
- **Auth**: POST `/api/v1/auth/register`, `/api/v1/auth/login`, `/api/v1/auth/refresh`
- **Auth (Phone)**: POST `/api/v1/auth/send-otp`, `/api/v1/auth/verify-otp`, `/api/v1/auth/phone/register`, `/api/v1/auth/phone/login`
- **Users**: GET `/api/v1/users/me`, PUT `/api/v1/users/me`, DELETE `/api/v1/users/me` (회원탈퇴, body: `{password}`), GET `/api/v1/users/search?q=` (닉네임 또는 닉네임#태그)
- **Friends**: GET `/api/v1/friends`, POST `/api/v1/friends` (body: `{friendId}`), PUT `/api/v1/friends/{id}/accept`, DELETE `/api/v1/friends/{id}`, GET `/api/v1/friends/pending`
- **Chats**: GET `/api/v1/chats`, POST `/api/v1/chats`, GET `/api/v1/chats/{roomId}`
- **Messages**: GET `/api/v1/chats/{roomId}/messages?cursor=&size=20`, DELETE `/api/v1/chats/{roomId}/messages/{messageId}` (5분 이내 본인 메시지 삭제), PUT `/api/v1/chats/{roomId}/read`
- **Upload**: POST `/api/v1/upload/presign` (body: `{fileName, contentType, contentLength, purpose, chatRoomId?}`) → `{uploadUrl, publicUrl}`
- **WebSocket**: STOMP endpoint `/ws`, 구독 `/topic/chat/{roomId}`, `/queue/user/{userId}`

## 코딩 컨벤션
- Kotlin: 코루틴 사용 안 함 (일반 Spring MVC), data class 적극 활용
- DTO: Request/Response 분리 (XxxRequest, XxxResponse)
- 예외: 글로벌 @RestControllerAdvice 핸들러
- Flutter: Riverpod + GoRouter, feature-first 구조

## 개발 룰
- **버그/에러 수정 시 에이전트를 병렬로 활용할 것**: 독립적인 이슈는 각각 별도 에이전트에게 할당하여 동시 수정
- **프론트-백엔드 API 경로는 반드시 이 문서의 "API 엔드포인트" 섹션을 정본으로 참조** — 프론트/백 간 경로 불일치 방지
- **에러 응답 파싱**: DioException에서 서버 에러 메시지(`response.data['error']['message']`)를 추출하여 사용자에게 표시
- **수정 후 반드시 검증**: 백엔드 `./gradlew build -x test`, 프론트 `flutter analyze`
- **SMS Provider 설정**: `SMS_PROVIDER=stub` (개발), `SMS_PROVIDER=solapi` (프로덕션). StubSmsService는 콘솔에 OTP 출력
- **Solapi 환경변수**: `SMS_SOLAPI_API_KEY`, `SMS_SOLAPI_API_SECRET`, `SMS_SOLAPI_SENDER`
- **Blind Index Secret**: `BLIND_INDEX_SECRET` 환경변수로 관리, 프로덕션에서 반드시 변경
- **이메일 필드 제거됨**: V9 마이그레이션으로 email 컬럼 완전 삭제, 전화번호+닉네임#태그 기반
- **미디어 저장소**: Cloudflare R2 (S3 호환), Presigned URL 방식 (서버 프록시 없음)
- **R2 환경변수**: `R2_ENDPOINT`, `R2_BUCKET`, `R2_ACCESS_KEY`, `R2_SECRET_KEY`, `R2_PUBLIC_URL`
- **업로드 제한**: 이미지 10MB (JPEG/PNG/WebP/GIF), 동영상 50MB/3분 (MP4/MOV/WebM)
- **버킷 구조**: `profiles/{userId}/{uuid}.{ext}`, `chats/{roomId}/{uuid}.{ext}`
