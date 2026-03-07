class UserModel {
  final String uid; // unique ID from Firebase Auth
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime? lastSeen; // NEW: Track when user was last active
  final String? profileImageUrl; // NEW: Profile picture URL
  final bool isEmailVerified; // NEW: Email verification status
  final DateTime? emailVerifiedAt; // NEW: When email was verified

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.lastSeen,
    this.profileImageUrl,
    this.isEmailVerified = false, // Default to false for safety
    this.emailVerifiedAt,
  });

  // 🔒 SAFE Build from Firestore document with proper error handling
  factory UserModel.fromMap(Map<String, dynamic> data) {
    try {
      return UserModel(
        uid: data['uid']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        displayName: data['displayName']?.toString() ?? 'Anonymous',

        // Safe DateTime parsing with fallback
        createdAt: data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : DateTime.now(),

        lastSeen: data['lastSeen'] != null
            ? DateTime.parse(data['lastSeen'])
            : null,

        emailVerifiedAt: data['emailVerifiedAt'] != null
            ? DateTime.parse(data['emailVerifiedAt'])
            : null,

        profileImageUrl: data['profileImageUrl']?.toString(),
        isEmailVerified: data['isEmailVerified'] ?? false,
      );
    } catch (e) {
      // If parsing fails, return safe default user
      return UserModel(
        uid: data['uid']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        displayName: 'Anonymous User',
        createdAt: DateTime.now(),
      );
    }
  }

  // Convert to a Map to save in Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
    };
  }

  // 🚀 PERFORMANCE: copyWith for immutable updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? profileImageUrl,
    bool? isEmailVerified,
    DateTime? emailVerifiedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }

  // 🚀 PERFORMANCE: Proper equality for Provider optimization
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.createdAt == createdAt &&
        other.lastSeen == lastSeen &&
        other.profileImageUrl == profileImageUrl &&
        other.isEmailVerified == isEmailVerified &&
        other.emailVerifiedAt == emailVerifiedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        createdAt.hashCode ^
        (lastSeen?.hashCode ?? 0) ^
        (profileImageUrl?.hashCode ?? 0) ^
        isEmailVerified.hashCode ^
        (emailVerifiedAt?.hashCode ?? 0);
  }

  // 🐛 DEBUGGING: Clear toString for easier debugging
  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, '
        'isEmailVerified: $isEmailVerified, createdAt: $createdAt)';
  }

  // 📧 HELPER METHODS for business logic
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  String get initials {
    final names = displayName.trim().split(' ');
    if (names.isEmpty) return 'A';
    if (names.length == 1) return names[0].substring(0, 1).toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  // Time since user was created
  Duration get accountAge => DateTime.now().difference(createdAt);
}
