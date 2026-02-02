

import 'package:dart_frog/dart_frog.dart';

import '../chat.dart';

Response onRequest(RequestContext context, String id) {
  // ১. ম্যাপে ইউজার আইডি আছে কি না চেক করো
  final isOnline = activeClients.containsKey(id);

  // ২. রেজাল্ট রিটার্ন করো
  return Response.json(body: {
    'userId': id,
    'status': isOnline ? 'online' : 'offline',
  });
}