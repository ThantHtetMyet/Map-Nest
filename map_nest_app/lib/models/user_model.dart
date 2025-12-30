class UserModel {
  final String id;
  final String userId; // User ID for login
  final String? displayName;
  final String? mobileNumber;
  final String role; // 'user' or 'admin' (stored directly in user document)
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.userId,
    this.displayName,
    this.mobileNumber,
    this.role = 'user', // Default role is 'user'
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'mobileNumber': mobileNumber,
      'role': role.toUpperCase(), // Store as uppercase: 'USER' or 'ADMIN'
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Support both uppercase and lowercase role values
    final roleValue = map['role'] ?? 'user';
    final role = roleValue.toString().toLowerCase(); // Normalize to lowercase
    
    return UserModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      displayName: map['displayName'],
      mobileNumber: map['mobileNumber'],
      role: role, // 'user' or 'admin'
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
    );
  }

  // Helper methods
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => role.toLowerCase() == 'user';
  
  // Check if user can manage posts (both user and admin can)
  bool get canManagePosts => isUser || isAdmin;
}
