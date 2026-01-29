import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  // মেথড চেক করা (শুধু GET এলাউ করা)
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final db = context.read<Db>();
  final collection = db.collection('messages');

  // ডাটাবেস থেকে সব মেসেজ খুঁজে আনা (টাইমস্ট্যাম্প অনুযায়ী সর্ট করে)
  final messages = await collection.find(
    where.sortBy('timestamp', descending: false),
  ).toList();

  return Response.json(body: messages);
}