import 'package:mongo_dart/mongo_dart.dart';

class DB {
  static late Db db;
  static late DbCollection messagesCollection;

  static Future<void> init() async {
    // MongoDB URI: যদি local MongoDB থাকে
    db = Db('mongodb://localhost:27017/chat_app');


    await db.open();
    print('✅ Connected to MongoDB');

    // Collection
    messagesCollection = db.collection('messages');
  }

  static Future<void> saveMessage(Map<String, dynamic> msg) async {
    await messagesCollection.insertOne(msg);
  }

  static Future<List<Map<String, dynamic>>> getMessagesForUser(String userId) async {
    return await messagesCollection.find({
      r'$or': [
        {'from': userId},
        {'to': userId},
      ]
    }).toList();
  }
}
