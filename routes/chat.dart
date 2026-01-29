import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

// অনলাইন ক্লায়েন্টদের লিস্ট (UserId -> WebSocketChannel)
final Map<String, dynamic> _activeClients = {};
const _uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
  // Middleware থেকে ডাটাবেস কালেকশন এক্সেস করা
  final db = context.read<Db>();
  final messagesCol = db.collection('messages');

  final handler = webSocketHandler((channel, protocol) {
    String? currentUserId;

    channel.stream.listen(
          (rawData) async {
        try {
          final data = jsonDecode(rawData.toString()) as Map<String, dynamic>;
          final type = data['type'] as String?;

          // ১. ইউজার জয়েন করা
          if (type == 'join') {
            final userId = data['userId'] as String?;
            if (userId != null) {
              currentUserId = userId;
              _activeClients[currentUserId!] = channel;
              print('👤 User Joined: $currentUserId');

              channel.sink.add(jsonEncode({
                'type': 'status',
                'message': 'Connected as $currentUserId'
              }));
            }
            return;
          }

          // ২. চ্যাট মেসেজ হ্যান্ডেল করা
          if (type == 'message') {
            final from = data['from'] as String? ?? 'unknown';
            final to = data['to'] as String? ?? 'unknown';
            final text = data['message'] as String? ?? '';

            if (text.isEmpty) return;

            // ডাটাবেস মডেল (ObjectId এরর ফিক্স সহ)
            final messageModel = {
              '_id': ObjectId(), // মঙ্গোডিবি-র নিজস্ব আইডি
              'id': _uuid.v4(),  // আপনার কাস্টম আইডি
              'from': from,
              'to': to,
              'message': text,
              'timestamp': DateTime.now().toIso8601String(),
            };

            // MongoDB-তে মেসেজ সেভ করা
            await messagesCol.insertOne(messageModel);
            print('💾 Message Saved to MongoDB Successfully!');

            final responsePayload = jsonEncode({
              'type': 'new_message',
              ...messageModel,
              '_id': messageModel['_id'].toString(), // ক্লায়েন্টকে পাঠানোর আগে ObjectId-কে String করে নেয়া
            });

            // রিসিভার যদি অনলাইন থাকে তবে তাকে পাঠানো
            if (_activeClients.containsKey(to)) {
              _activeClients[to].sink.add(responsePayload);
              print('📤 Message delivered to $to');
            }

            // প্রেরককেও (নিজে) কনফার্মেশন হিসেবে পাঠানো
            channel.sink.add(responsePayload);
          }
        } catch (e) {
          print('❌ Error handling message: $e');
        }
      },
      onDone: () {
        if (currentUserId != null) {
          _activeClients.remove(currentUserId);
          print('❌ User Left: $currentUserId');
        }
      },
    );
  });

  return handler(context);
}