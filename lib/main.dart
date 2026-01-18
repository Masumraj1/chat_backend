import 'chat_server.dart';
import 'db.dart';

Future<void> main() async {
  await DB.init(); // MongoDB connect
  final server = ChatServer(port: 8081);
  await server.start();
}
