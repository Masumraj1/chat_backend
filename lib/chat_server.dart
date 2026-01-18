import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'db.dart';

class ChatServer {
  final int port;
  final Map<String, WebSocket> _clients = {}; // userId -> socket
  final uuid = Uuid();

  ChatServer({this.port = 8081});

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('💬 Chat server running on ws://localhost:$port');

    await for (HttpRequest request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleClient(socket);
      } else {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
      }
    }
  }

  void _handleClient(WebSocket socket) {
    String? userId;

    socket.listen((data) async {
      final decoded = jsonDecode(data);

      // Join
      if (decoded['type'] == 'join') {
        userId = decoded['userId'];
        _clients[userId!] = socket;
        print('👤 User joined: $userId');

        // Send previous messages to this user
        final msgs = await DB.getMessagesForUser(userId!);
        for (var msg in msgs) {
          socket.add(jsonEncode(msg));
        }
        return;
      }

      // Chat message
      final from = decoded['from'];
      final to = decoded['to'];
      final messageText = decoded['message'];

      final message = {
        'id': uuid.v4(),
        'from': from,
        'to': to,
        'message': messageText,
        'timestamp': DateTime.now().toIso8601String(),
      };


      // Save to MongoDB
      await DB.saveMessage(message);

      // Send to receiver
      final receiverSocket = _clients[to];
      if (receiverSocket != null) {
        receiverSocket.add(jsonEncode(message));
      }

      // Optional: sender also receives it
      socket.add(jsonEncode(message));
    }, onDone: () {
      if (userId != null) {
        _clients.remove(userId);
        print('❌ User left: $userId');
      }
    });
  }
}
