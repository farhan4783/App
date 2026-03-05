# ChatApp — WhatsApp-like Live Messaging

A real-time chat application built with **Flutter + Dart** (frontend) and **Node.js + Socket.IO** (backend). No Firebase, no phone numbers.

---

## Project Structure

```
AApp/
├── chatapp/          ← Flutter mobile app
└── chatapp-backend/  ← Node.js + Socket.IO server
```

---

## 🛠️ Backend Setup (Node.js)

### 1. Prerequisites
- Node.js 18+
- PostgreSQL database running locally (or use a cloud DB like Supabase/Neon)

### 2. Configure Environment
```bash
cd chatapp-backend
cp .env.example .env
```

Edit `.env`:
```env
DATABASE_URL="postgresql://YOUR_USER:YOUR_PASS@localhost:5432/chatapp"
JWT_SECRET="change_this_to_a_long_random_string"
JWT_REFRESH_SECRET="another_long_random_string"

# Optional - for media uploads
CLOUDINARY_CLOUD_NAME="your_cloud_name"
CLOUDINARY_API_KEY="your_api_key"
CLOUDINARY_API_SECRET="your_api_secret"
```

### 3. Set Up Database
```bash
npx prisma generate
npx prisma migrate dev --name init
```

### 4. Start Server
```bash
npm run dev
```
Server runs on: `http://localhost:3001`

---

## 📱 Flutter App Setup

### 1. Prerequisites
- Flutter SDK 3.x
- Android Studio / Xcode

### 2. Configure Server URL
Edit `lib/core/constants/app_constants.dart`:
```dart
// For Android emulator (localhost)
static const String baseUrl = 'http://10.0.2.2:3001';
static const String socketUrl = 'http://10.0.2.2:3001';

// For real device on same WiFi (use your PC's local IP)
// static const String baseUrl = 'http://192.168.x.x:3001';
// static const String socketUrl = 'http://192.168.x.x:3001';
```

### 3. Add Inter Font
Download [Inter font](https://fonts.google.com/specimen/Inter) and place `.ttf` files in `assets/fonts/`:
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`

Or remove the `fonts:` section from `pubspec.yaml` to use the device default font.

### 4. Get Dependencies & Run
```bash
cd chatapp
flutter pub get
flutter run
```

---

## ✨ Features

| Feature | Status |
|---|---|
| Email + Username auth (no phone) | ✅ |
| Real-time messaging via WebSocket | ✅ |
| Typing indicators | ✅ |
| Message read receipts (✓/✓✓/🔵) | ✅ |
| Online / last seen status | ✅ |
| Image sharing | ✅ |
| File sharing | ✅ |
| Group chats | ✅ |
| User search by username/email | ✅ |
| Dark & Light themes | ✅ |
| JWT authentication + auto-refresh | ✅ |
| Profile edit (name, bio, photo) | ✅ |

---

## 🔌 WebSocket Events Reference

### Client → Server
| Event | Payload |
|---|---|
| `join_chats` | `{ chatIds: string[] }` |
| `send_message` | `{ chatId, text?, type, mediaUrl?, fileName? }` |
| `typing_start` | `{ chatId }` |
| `typing_stop` | `{ chatId }` |
| `message_read` | `{ chatId, messageId }` |

### Server → Client
| Event | Payload |
|---|---|
| `new_message` | Full `MessageModel` object |
| `user_typing` | `{ chatId, userId, displayName }` |
| `user_stop_typing` | `{ chatId, userId }` |
| `message_status` | `{ messageId, status, seenBy }` |
| `user_status` | `{ userId, isOnline, lastSeen }` |
