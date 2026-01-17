import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safebrowser/features/logs/data/models/log_model.dart';
import 'package:safebrowser/core/services/firebase_service.dart';

class LogService {
  final FirebaseFirestore _db = firebaseService.firestore;

  Future<void> addLog(String userId, LogModel log) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('logs')
          .add(log.toFirestore());
    } catch (e) {
      print('❌ LogService Error: $e');
    }
  }

  Stream<List<LogModel>> getLogs(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LogModel.fromFirestore(doc))
            .toList());
  }
}

final logService = LogService();
