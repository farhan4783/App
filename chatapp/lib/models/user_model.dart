class UserModel {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    required this.isOnline,
    required this.lastSeen,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Unknown',
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'bio': bio,
        'isOnline': isOnline,
        'lastSeen': lastSeen.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
    );
  }
}
