import '../../../core/models/user_model.dart';

/// Response model for successful authentication
class AuthResponse {
  final String? accessToken;
  final String? sessionToken;
  final String? expiresIn;
  final UserModel? user;
  final bool requiresVerification;
  final String? message;
  final String? email;

  AuthResponse({
    this.accessToken,
    this.sessionToken,
    this.expiresIn,
    this.user,
    this.requiresVerification = false,
    this.message,
    this.email,
  });

  bool get isSuccess => accessToken != null && sessionToken != null;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken']?.toString(),
      sessionToken: json['sessionToken']?.toString(),
      expiresIn: json['expiresIn']?.toString(),
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      requiresVerification: json['requiresVerification'] as bool? ?? false,
      message: json['message']?.toString(),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (accessToken != null) 'accessToken': accessToken,
      if (sessionToken != null) 'sessionToken': sessionToken,
      if (expiresIn != null) 'expiresIn': expiresIn,
      if (user != null) 'user': user!.toJson(),
      'requiresVerification': requiresVerification,
      if (message != null) 'message': message,
      if (email != null) 'email': email,
    };
  }
}

/// Response model for registration
class RegisterResponse {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String message;
  final DateTime createdAt;

  RegisterResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.message,
    required this.createdAt,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Response model for verification status
class VerificationResponse {
  final String message;
  final String email;

  VerificationResponse({required this.message, required this.email});

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      message: json['message'] as String,
      email: json['email'] as String,
    );
  }
}

/// Response model for logout
class LogoutResponse {
  final String message;

  LogoutResponse({required this.message});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(message: json['message'] as String);
  }
}
