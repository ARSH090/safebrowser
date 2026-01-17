import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safebrowser/features/parent/data/models/child_profile_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ChildProfile>> getChildProfiles(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('childProfiles')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChildProfile.fromFirestore(doc))
            .toList());
  }

  Future<void> addChildProfile(String userId, ChildProfile profile) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('childProfiles')
        .add(profile.toFirestore());
  }

  Future<void> updateChildProfile(String userId, ChildProfile profile) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('childProfiles')
        .doc(profile.id)
        .update(profile.toFirestore());
  }

  Future<void> deleteChildProfile(String userId, String profileId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('childProfiles')
        .doc(profileId)
        .delete();
  }
}
