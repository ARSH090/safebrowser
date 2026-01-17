// import 'package:cloud_firestore/cloud_firestore.dart';  // Disabled

class UserModel {
  final String id;
  final String email;

  UserModel({required this.id, required this.email});

  factory UserModel.fromFirestore(dynamic doc) {  // Changed from DocumentSnapshot
    Map data = doc.data() as Map<String, dynamic>;;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
    };
  }
}
