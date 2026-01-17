import 'package:cloud_firestore/cloud_firestore.dart';

enum LogType { phishing, text, image }

class LogModel {
  final String id;
  final LogType type;
  final String reason;
  final Timestamp timestamp;
  final String childId;
  final String url;

  LogModel({
    required this.id,
    required this.type,
    required this.reason,
    required this.timestamp,
    required this.childId,
    required this.url,
  });

  factory LogModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return LogModel(
      id: doc.id,
      type: LogType.values[data['type'] ?? 0],
      reason: data['reason'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      childId: data['childId'] ?? '',
      url: data['url'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.index,
      'reason': reason,
      'timestamp': timestamp,
      'childId': childId,
      'url': url,
    };
  }
}
