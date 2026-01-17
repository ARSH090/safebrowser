import 'package:cloud_firestore/cloud_firestore.dart';

enum AgeGroup {
  fiveToEight,
  nineToTwelve,
  thirteenPlus,
}

class ChildProfile {
  final String id;
  final String name;
  final AgeGroup ageGroup;
  final List<String> blockedDomains;
  final List<String> whitelistedDomains;
  final int phishingProtectionLevel;
  final String pin;

  ChildProfile({
    required this.id,
    required this.name,
    required this.ageGroup,
    required this.blockedDomains,
    required this.whitelistedDomains,
    required this.phishingProtectionLevel,
    required this.pin,
  });

  factory ChildProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChildProfile(
      id: doc.id,
      name: data['name'] ?? '',
      ageGroup: AgeGroup.values[data['ageGroup'] ?? 0],
      blockedDomains: List<String>.from(data['blockedDomains'] ?? []),
      whitelistedDomains: List<String>.from(data['whitelistedDomains'] ?? []),
      phishingProtectionLevel: data['phishingProtectionLevel'] ?? 0,
      pin: data['pin'] ?? '1234',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ageGroup': ageGroup.index,
      'blockedDomains': blockedDomains,
      'whitelistedDomains': whitelistedDomains,
      'phishingProtectionLevel': phishingProtectionLevel,
      'pin': pin,
    };
  }

  ChildProfile copyWith({
    String? id,
    String? name,
    AgeGroup? ageGroup,
    List<String>? blockedDomains,
    List<String>? whitelistedDomains,
    int? phishingProtectionLevel,
    String? pin,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      blockedDomains: blockedDomains ?? this.blockedDomains,
      whitelistedDomains: whitelistedDomains ?? this.whitelistedDomains,
      phishingProtectionLevel: phishingProtectionLevel ?? this.phishingProtectionLevel,
      pin: pin ?? this.pin,
    );
  }
}
