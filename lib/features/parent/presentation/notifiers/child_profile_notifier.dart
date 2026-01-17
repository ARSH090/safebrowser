import 'dart:collection';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:safebrowser/features/parent/data/models/child_profile_model.dart';
import 'package:safebrowser/features/parent/data/services/firestore_service.dart';

class ChildProfileNotifier with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<ChildProfile>>? _profilesSubscription;
  List<ChildProfile> _profiles = [];

  UnmodifiableListView<ChildProfile> get profiles => UnmodifiableListView(_profiles);

  void fetchChildProfiles(String userId) {
    _profilesSubscription?.cancel();
    _profilesSubscription = _firestoreService.getChildProfiles(userId).listen((profiles) {
      _profiles = profiles;
      notifyListeners();
    });
  }

  Future<void> addChildProfile(String userId, ChildProfile profile) async {
    await _firestoreService.addChildProfile(userId, profile);
  }

  Future<void> updateChildProfile(String userId, ChildProfile profile) async {
    await _firestoreService.updateChildProfile(userId, profile);
  }

  Future<void> deleteChildProfile(String userId, String profileId) async {
    await _firestoreService.deleteChildProfile(userId, profileId);
  }

  @override
  void dispose() {
    _profilesSubscription?.cancel();
    super.dispose();
  }
}
