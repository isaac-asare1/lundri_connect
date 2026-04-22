class AppUserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? profileImageUrl;
  final String? addressLine;
  final bool isOnline;
  final DateTime createdAt;

  const AppUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    this.addressLine,
    this.isOnline = false,
    required this.createdAt,
  });

  AppUserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? profileImageUrl,
    String? addressLine,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      addressLine: addressLine ?? this.addressLine,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'addressLine': addressLine,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      role: map['role'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String?,
      addressLine: map['addressLine'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
