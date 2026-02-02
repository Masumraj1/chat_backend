import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';


// ডাটাবেস কানেকশন গ্লোবালি রাখা হচ্ছে
Db? _db;

Handler middleware(Handler handler) {
  return (context) async {
    // ডাটাবেস কানেক্টেড না থাকলে কানেক্ট করবে
    if (_db == null || !_db!.isConnected) {
      _db = await Db.create('mongodb://localhost:27017/chat_app');
      await _db!.open();
      print('✅ MongoDB Connected Successfully');
    }

    // ডাটাবেসকে প্রোভাইডার হিসেবে পাস করা হচ্ছে
    return handler.use(provider<Db>((_) => _db!))(context);
  };
}