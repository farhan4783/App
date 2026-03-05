# ChatApp — Build Walkthrough

A full-stack, WhatsApp-like live messaging app built with **Flutter + Node.js + Socket.IO**. No Firebase. No phone numbers.

---

## What Was Built

### Backend (`chatapp-backend/`)

| File | Purpose |
|---|---|
| [prisma/schema.prisma](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/prisma/schema.prisma) | PostgreSQL schema: [User](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/models/user_model.dart#1-70), [Chat](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/main.dart#16-34), [ChatMember](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/models/chat_model.dart#4-26), [Message](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/services/socket_service.dart#128-143) |
| [src/index.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/index.js) | Express + Socket.IO server entry point |
| [src/config/db.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/config/db.js) | Prisma client singleton |
| [src/config/cloudinary.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/config/cloudinary.js) | Cloudinary media upload config |
| [src/middleware/auth.middleware.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/middleware/auth.middleware.js) | JWT verification for REST routes |
| [src/controllers/auth.controller.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/controllers/auth.controller.js) | Register, login, refresh token |
| [src/controllers/user.controller.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/controllers/user.controller.js) | Get me, search users, update profile |
| [src/controllers/chat.controller.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/controllers/chat.controller.js) | Get chats, create direct/group chat, get messages |
| [src/controllers/media.controller.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/controllers/media.controller.js) | Cloudinary file upload |
| `src/routes/*.js` | Express route definitions |
| [src/socket/socket.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/socket/socket.js) | Socket.IO server with JWT auth middleware |
| [src/socket/handlers/message.handler.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/socket/handlers/message.handler.js) | Send message, DELIVERED/READ receipts |
| [src/socket/handlers/typing.handler.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/socket/handlers/typing.handler.js) | Typing start/stop broadcast |
| [src/socket/handlers/status.handler.js](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp-backend/src/socket/handlers/status.handler.js) | Online/offline presence broadcast |

### Flutter App (`chatapp/`)

| Layer | Files |
|---|---|
| **Core** | [app_theme.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/core/theme/app_theme.dart), [app_colors.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/core/theme/app_colors.dart), [app_constants.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/core/constants/app_constants.dart), [validators.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/core/utils/validators.dart) |
| **Models** | [user_model.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/models/user_model.dart), [message_model.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/models/message_model.dart), [chat_model.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/models/chat_model.dart) |
| **Services** | [api_service.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/services/api_service.dart) (Dio + JWT refresh), [socket_service.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/services/socket_service.dart) (Socket.IO streams), [auth_service.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/services/auth_service.dart), [chat_service.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/services/chat_service.dart) |
| **Providers** | [auth_provider.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/providers/auth_provider.dart), [chat_provider.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/providers/chat_provider.dart) (chat list, messages, typing, user status) |
| **Router** | [app_router.dart](file:///c:/Users/FARAZ%20KHAN/Desktop/DEKSTOP/PROJECTS/AApp/chatapp/lib/router/app_router.dart) (go_router with auth-based redirect) |
| **Screens** | Splash, Login, Register, Home, Chat, Search Users, Profile, Settings, Create Group |

---

## Features Implemented

| Feature | Notes |
|---|---|
| ✅ Email + Username login | No phone number anywhere |
| ✅ Real-time messages | Via Socket.IO room events |
| ✅ Typing indicator | 2-second debounce auto-clear |
| ✅ Read receipts (✓/✓✓/🔵) | `sent` → `delivered` → `read` |
| ✅ Online / last seen | App lifecycle + socket disconnect |
| ✅ Image upload | Cloudinary via REST; sent as `IMAGE` message type |
| ✅ Group chats | Admin-managed, `seenBy` per member |
| ✅ User search | By username or email |
| ✅ Dark / Light themes | Material 3 with custom teal palette |
| ✅ JWT + auto-refresh | Invisible token refresh on 401 |
| ✅ Profile edit | Name, bio, avatar photo |

---

## How to Run

### Step 1: Backend

```bash
cd chatapp-backend
cp .env.example .env
# Edit .env — add your PostgreSQL connection string and JWT secrets
npx prisma generate
npx prisma migrate dev --name init
npm run dev
# Server: http://localhost:3001
```

### Step 2: Flutter App

```bash
cd chatapp
# Update lib/core/constants/app_constants.dart if using real device
flutter pub get
flutter run
```

> [!NOTE]
> On an **Android emulator**, `10.0.2.2` maps to your PC's localhost.
> On a **physical device** (same WiFi), replace with your PC's LAN IP (e.g., `192.168.1.x`).

---

## Verification Checklist

- [ ] Backend starts without errors (`npm run dev`)
- [ ] `GET http://localhost:3001/health` returns `{ status: "ok" }`
- [ ] Register User A → lands on Home screen
- [ ] Register User B (different device/emulator)
- [ ] Search User B by username → appears in results
- [ ] Tap User B → Chat screen opens
- [ ] Send message from A → appears on B in real-time
- [ ] Reply from B → both see it instantly
- [ ] Typing indicator shows on the other device
- [ ] Image sends and displays correctly
- [ ] Dark/Light theme toggle works in Settings
- [ ] Logout and login again → chats still visible
