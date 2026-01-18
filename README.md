# Dart 1-to-1 Chat Server (MongoDB সহ)

এই project একটি **real-time 1-to-1 chat server** তৈরি করার জন্য।  
Dart WebSocket server এবং MongoDB ব্যবহার করে বানানো হয়েছে।

---

## **Project Structure**

dart_chat_backend/
├─ lib/
│ ├─ main.dart # Entry point, server start করে
│ ├─ chat_server.dart # WebSocket server logic
│ └─ db.dart # MongoDB connection + save/fetch messages
└─ pubspec.yaml # Dart dependencies


---

## **File Explains (Bangla)**

### 1️⃣ `db.dart`
- MongoDB এর সাথে connect করার জন্য।
- Function গুলো:
    - `init()` → MongoDB open করে।
    - `saveMessage(msg)` → message save করে।
    - `getMessagesForUser(userId)` → reconnect হলে previous messages fetch করে।

**Important line explanation:**

[//]: # (```dart)
db = Db('mongodb://localhost:27017/chat_app');



2️⃣ chat_server.dart

WebSocket server তৈরি করা হয়।

Connected users Map এ রাখা হয়।

Function গুলো:

_handleClient(socket) → নতুন client join হলে handle করে।

_sendToUser(from, to, message) → private message পাঠায়।