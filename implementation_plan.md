# Flutter Live Messaging App — Implementation Plan (WebSocket Edition)

Real-time chat app built in **Flutter/Dart** inspired by WhatsApp — **no phone numbers, no Firebase**. Authentication uses **email + username**. The backend is a custom **Node.js + Socket.IO** server with **PostgreSQL** for persistence.

---

## User Review Required

> [!IMPORTANT]
> **No Firebase at all** — auth, storage, and real-time messaging are all handled by the custom Node.js server.

> [!IMPORTANT]
> **Database**: Plan uses **PostgreSQL** (via Prisma ORM). If you prefer **MongoDB**, let me know and I'll adjust the schema.

> [!IMPORTANT]
> **Media Storage**: Files/images are stored on **Cloudinary** (free tier). Can be swapped for a local `uploads/` folder on the server if you prefer no third-party services.

> [!WARNING]
> **Push Notifications**: Without Firebase, push notifications use **OneSignal** (free tier). Alternatively we can skip notifications for now and add later.

---

## Architecture Overview

```
Flutter App  ←──── WebSocket (Socket.IO) ────→  Node.js Server
     │                                                │
     │  HTTP (REST)                            ┌──────┴──────┐
     │  (login/register/media upload)          │  PostgreSQL  │
     └────────────────────────────────────────→│  (Prisma)    │
                                               └─────────────┘
```

- **REST API** → auth (login/register), media upload, fetch user profiles, chat history
- **WebSocket** → all real-time events (new message, typing, read receipt, online status)

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter 3.x (Dart) |
| **State Management** | Riverpod |
| **WebSocket Client** | `socket_io_client` (Dart) |
| **HTTP Client** | `dio` |
| **Backend Runtime** | Node.js 20+ |
| **WebSocket Server** | Socket.IO 4.x |
| **REST Framework** | Express.js |
| **Database** | PostgreSQL + Prisma ORM |
| **Auth** | JWT (access + refresh tokens) |
| **Password Hashing** | bcrypt |
| **Media Storage** | Cloudinary |
| **Push Notifications** | OneSignal |
| **Local Cache (Flutter)** | Hive + shared_preferences |

---

## Proposed Changes

---

### Backend — Node.js + Socket.IO Server

#### [NEW] `server/` — Project root

```
server/
├── prisma/
│   └── schema.prisma          ← DB schema
├── src/
│   ├── index.js               ← Entry point (Express + Socket.IO)
│   ├── config/
│   │   ├── db.js              ← Prisma client
│   │   └── cloudinary.js      ← Cloudinary config
│   ├── middleware/
│   │   └── auth.middleware.js ← JWT verification
│   ├── routes/
│   │   ├── auth.routes.js     ← /api/auth
│   │   ├── user.routes.js     ← /api/users
│   │   ├── chat.routes.js     ← /api/chats
│   │   └── media.routes.js    ← /api/media/upload
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── user.controller.js
│   │   ├── chat.controller.js
│   │   └── media.controller.js
│   └── socket/
│       ├── socket.js          ← Socket.IO server setup
│       └── handlers/
│           ├── message.handler.js
│           ├── typing.handler.js
│           ├── status.handler.js  ← online/offline/read
│           └── group.handler.js
└── package.json
```

#### [NEW] `prisma/schema.prisma` — Database Schema

```prisma
model User {
  id          String    @id @default(uuid())
  username    String    @unique
  email       String    @unique
  displayName String
  passwordHash String
  photoUrl    String?
  bio         String?
  isOnline    Boolean   @default(false)
  lastSeen    DateTime  @default(now())
  createdAt   DateTime  @default(now())

  sentMessages     Message[]  @relation("sender")
  chatMemberships  ChatMember[]
  oneSignalId      String?
}

model Chat {
  id          String    @id @default(uuid())
  isGroup     Boolean   @default(false)
  groupName   String?
  groupPhoto  String?
  createdAt   DateTime  @default(now())

  members     ChatMember[]
  messages    Message[]
}

model ChatMember {
  id      String @id @default(uuid())
  user    User   @relation(fields: [userId], references: [id])
  userId  String
  chat    Chat   @relation(fields: [chatId], references: [id])
  chatId  String
  isAdmin Boolean @default(false)

  @@unique([userId, chatId])
}

model Message {
  id        String      @id @default(uuid())
  chat      Chat        @relation(fields: [chatId], references: [id])
  chatId    String
  sender    User        @relation("sender", fields: [senderId], references: [id])
  senderId  String
  text      String?
  mediaUrl  String?
  type      MessageType @default(TEXT)
  status    MsgStatus   @default(SENT)
  seenBy    String[]    @default([])
  sentAt    DateTime    @default(now())
}

enum MessageType { TEXT IMAGE FILE AUDIO }
enum MsgStatus  { SENT DELIVERED READ }
```

#### [NEW] REST API Endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | ❌ | Create account |
| POST | `/api/auth/login` | ❌ | Login → returns JWT |
| POST | `/api/auth/refresh` | ❌ | Refresh access token |
| GET | `/api/users/search?q=username` | ✅ | Search users |
| GET | `/api/users/:id` | ✅ | Get user profile |
| PATCH | `/api/users/me` | ✅ | Update own profile |
| GET | `/api/chats` | ✅ | Get all chats |
| POST | `/api/chats` | ✅ | Create 1-on-1 or group chat |
| GET | `/api/chats/:id/messages` | ✅ | Get message history (paginated) |
| POST | `/api/media/upload` | ✅ | Upload image/file → returns URL |

#### [NEW] Socket.IO Events

**Client → Server:**
| Event | Payload | Description |
|---|---|---|
| `join_chats` | `{ chatIds[] }` | Join all user's chat rooms |
| `send_message` | `{ chatId, text, type, mediaUrl }` | Send a message |
| `typing_start` | `{ chatId }` | Broadcast typing indicator |
| `typing_stop` | `{ chatId }` | Stop typing indicator |
| `message_read` | `{ chatId, messageId }` | Mark message as read |
| `disconnect` | — | Server sets user offline |

**Server → Client:**
| Event | Payload | Description |
|---|---|---|
| `new_message` | `MessageObject` | New message received |
| `user_typing` | `{ chatId, userId }` | Someone is typing |
| `user_stop_typing` | `{ chatId, userId }` | Typing stopped |
| `message_status` | `{ messageId, status }` | Status update (delivered/read) |
| `user_status` | `{ userId, isOnline, lastSeen }` | Online/offline change |
| `error` | `{ message }` | Error response |

---

### Flutter App

#### [NEW] `lib/` — Full Project Structure

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_theme.dart        ← Dark & Light themes
│   │   └── app_colors.dart
│   ├── constants/
│   │   └── api_constants.dart    ← Base URLs, Socket URL
│   └── utils/
│       ├── validators.dart
│       └── date_formatter.dart
├── models/
│   ├── user_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── services/
│   ├── api_service.dart          ← Dio HTTP client (auth, REST calls)
│   ├── socket_service.dart       ← Socket.IO client singleton
│   ├── auth_service.dart         ← Login, register, token storage
│   ├── chat_service.dart         ← Chat + message REST calls
│   ├── storage_service.dart      ← Media upload via REST
│   └── notification_service.dart ← OneSignal
├── providers/                    ← Riverpod
│   ├── auth_provider.dart
│   ├── socket_provider.dart
│   ├── chat_provider.dart
│   └── message_provider.dart     ← StreamController fed by socket events
├── screens/
│   ├── splash/splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/home_screen.dart     ← Chat list
│   ├── chat/chat_screen.dart     ← Real-time chat
│   ├── search/search_users_screen.dart
│   ├── group/create_group_screen.dart
│   ├── profile/profile_screen.dart
│   └── settings/settings_screen.dart
├── widgets/
│   ├── chat_tile.dart
│   ├── message_bubble.dart
│   ├── user_avatar.dart
│   └── typing_indicator.dart
└── router/app_router.dart        ← go_router
```

#### [NEW] `socket_service.dart` — Core WebSocket Logic

```dart
// Singleton wrapping socket_io_client
// - Connects with JWT in auth header
// - Exposes StreamControllers for each event type
// - Auto-reconnects on disconnect
class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  Stream<Message> get onNewMessage => _messageController.stream;
  Stream<TypingEvent> get onTyping   => _typingController.stream;
  Stream<StatusEvent> get onStatus   => _statusController.stream;

  void connect(String token) { ... }
  void sendMessage(String chatId, String text, MessageType type) { ... }
  void sendTyping(String chatId, bool isTyping) { ... }
  void markRead(String chatId, String messageId) { ... }
  void disconnect() { ... }
}
```

#### [NEW] Key Flutter Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Networking
  dio: ^5.x
  socket_io_client: ^2.x
  # State Management
  flutter_riverpod: ^2.x
  # Routing
  go_router: ^14.x
  # Media
  image_picker: ^1.x
  file_picker: ^8.x
  cached_network_image: ^3.x
  # Audio
  record: ^5.x
  just_audio: ^0.9.x
  # Local Storage
  hive_flutter: ^1.x
  shared_preferences: ^2.x
  flutter_secure_storage: ^9.x   ← store JWT securely
  # UI
  intl: ^0.19.x
  timeago: ^3.x
  emoji_picker_flutter: ^2.x
  # Notifications
  onesignal_flutter: ^5.x
```

---

## Screens Summary

| Screen | Purpose |
|---|---|
| **Splash** | Check stored JWT → route to Home or Login |
| **Login** | Email + password → POST `/api/auth/login` |
| **Register** | Email, username, display name, password |
| **Home** | Live chat list (sorted by latest message) |
| **Chat** | WebSocket real-time messages, media, typing dot |
| **Search Users** | Search by username → start chat |
| **Create Group** | Pick members, set name + photo |
| **Profile** | View/edit name, bio, avatar |
| **Settings** | Dark/light mode, logout, notification prefs |

---

## Verification Plan

### Automated Tests

```bash
# Backend
cd server && npm test          # Jest: auth routes, message controller

# Flutter
flutter test test/models/      # Model serialization tests
flutter test test/widgets/     # Widget snapshot tests
flutter analyze                # Zero errors
```

### Manual Verification

| # | Step | Expected |
|---|---|---|
| 1 | Register User A | JWT stored, lands on Home |
| 2 | Register User B (different device) | Same |
| 3 | User A searches User B by username | User B appears |
| 4 | Tap User B → open Chat | Empty chat, WebSocket room joined |
| 5 | Send text from A | Instant delivery to B via Socket.IO |
| 6 | Reply from B | Both see it instantly |
| 7 | Start typing on A | Typing indicator shows on B |
| 8 | Send image from A | Uploads to Cloudinary, shows on B |
| 9 | Check ✓/✓✓/🔵 status | Updates correctly |
| 10 | Kill app on B, send from A | OneSignal push notification fires |
| 11 | Create group chat | Both users see group in Home |
| 12 | Disconnect device B | A sees "last seen" update |
| 13 | Toggle dark/light mode | Instant theme switch |
