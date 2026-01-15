class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phone;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phone,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName {
    // Priority 1: firstName + lastName (from email/password signup)
    if (firstName != null && firstName!.isNotEmpty && 
        lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    // Priority 2: fullName (from Google OAuth - only if no firstName/lastName)
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    // Priority 3: email username as fallback
    return email.split('@')[0];
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      fullName: json['fullName']?.toString(),
      phone: json['phone']?.toString(),
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'phone': phone,
      'isVerified': isVerified,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    String? phone,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
