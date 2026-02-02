import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final db = context.read<Db>();
  final messagesCol = db.collection('messages');

  // মঙ্গোডিবি এগ্রিগেশন লজিক
  final pipeline = [
    {
      '\$match': {
        '\$or': [
          {'from': id}, // এখানে 'from' এবং 'to' স্ট্রিং হিসেবে থাকবে
          {'to': id}
        ]
      }
    },
    {
      '\$sort': {'timestamp': -1}
    },
    {
      '\$group': {
        '_id': {
          '\$cond': [
            // যদি প্রেরক (from) আমি হই, তবে পার্টনার হলো প্রাপক (to)
            // অন্যথায় পার্টনার হলো প্রেরক (from)
            {'\$eq': ['\$from', id]},
            '\$to',
            '\$from'
          ]
        },
        'lastMessage': {'\$first': '\$message'},
        'timestamp': {'\$first': '\$timestamp'},
        'sender': {'\$first': '\$from'}
      }
    },
    {
      '\$sort': {'timestamp': -1}
    }
  ];

  try {
    // এগ্রিগেশন রান করা
    final inboxList = await messagesCol.aggregateToStream(pipeline).toList();
    return Response.json(body: inboxList);
  } catch (e) {
    return Response.json(
      body: {'error': 'Failed to fetch inbox', 'details': e.toString()},
      statusCode: 500,
    );
  }
}