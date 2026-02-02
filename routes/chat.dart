import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

// GLOBAL REGISTRY: Stores all online users.
// Publicly accessible so other routes (like /status) can check online status.
final Map<String, dynamic> activeClients = {};
const _uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<Db>();
  final messagesCol = db.collection('messages');

  final handler = webSocketHandler((channel, protocol) {
    String? currentUserId;

    channel.stream.listen(
          (rawData) async {
        try {
          final data = jsonDecode(rawData.toString()) as Map<String, dynamic>;
          final type = data['type'] as String?;

          // --- 1. HANDLE USER JOIN ---
          if (type == 'join') {
            final userId = data['userId'] as String?;
            if (userId != null) {
              currentUserId = userId;
              // Register user in the global online map
              activeClients[currentUserId!] = channel;
              print('👤 User Joined: $currentUserId');

              channel.sink.add(jsonEncode({
                'type': 'status',
                'message': 'Connected as $currentUserId'
              }));
            }
            return;
          }

          // --- 2. HANDLE REAL-TIME CHAT ---
          if (type == 'message') {
            final from = data['from'] as String? ?? 'unknown';
            final to = data['to'] as String? ?? 'unknown';
            final text = data['message'] as String? ?? '';

            if (text.isEmpty) return;

            final messageModel = {
              '_id': ObjectId(),
              'id': _uuid.v4(),
              'from': from,
              'to': to,
              'message': text,
              'timestamp': DateTime.now().toIso8601String(),
            };

            // Save to Database
            await messagesCol.insertOne(messageModel);
            print('💾 Message Saved to MongoDB');

            final responsePayload = jsonEncode({
              'type': 'new_message',
              ...messageModel,
              '_id': messageModel['_id'].toString(),
            });

            // ROUTING: Deliver to Receiver if they are Online
            if (activeClients.containsKey(to)) {
              activeClients[to].sink.add(responsePayload);
              print('📤 Message delivered to $to');
            }

            // ECHO: Send back to the sender
            channel.sink.add(responsePayload);
          }
        } catch (e) {
          print('❌ Error handling message: $e');
        }
      },
      // --- 3. CLEANUP ON DISCONNECT ---
      // This is crucial for the Status System to work.
      // When the user closes the app, remove them from the 'Online' registry.
      onDone: () {
        if (currentUserId != null) {
          activeClients.remove(currentUserId);
          print('❌ User Left (Offline): $currentUserId');
        }
      },
    );
  });

  return handler(context);
}