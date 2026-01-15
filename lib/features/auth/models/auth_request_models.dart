/// Request model for user registration
class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phone;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
    };
  }
}

/// Request model for user login
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

/// Request model for Supabase OAuth login
class SupabaseLoginRequest {
  final String supabaseId;
  final String email;
  final String? fullName;
  final String? phone;

  SupabaseLoginRequest({
    required this.supabaseId,
    required this.email,
    this.fullName,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'supabaseId': supabaseId,
      'email': email,
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
    };
  }
}

/// Request model for email verification
class VerifyEmailRequest {
  final String email;
  final String code;

  VerifyEmailRequest({required this.email, required this.code});

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }
}

/// Request model for resending verification code
class ResendVerificationRequest {
  final String email;

  ResendVerificationRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// Request model for token refresh
class RefreshTokenRequest {
  final String sessionToken;

  RefreshTokenRequest({required this.sessionToken});

  Map<String, dynamic> toJson() {
    return {'sessionToken': sessionToken};
  }
}
