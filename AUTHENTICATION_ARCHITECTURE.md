# Authentication Architecture Documentation

## Overview

This Flutter application implements a **clean, scalable authentication architecture** following industry best practices. The system integrates with a NestJS backend API for email/password authentication with email verification.

## Architecture Layers

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                 │
│  (Screens: SignIn, SignUp, VerifyEmail)         │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│              Service Layer                      │
│  (AuthApiService, TokenStorageService)          │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│              Data Layer                         │
│  (Models: Requests, Responses, User)            │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│              Backend API                        │
│  (NestJS REST API - Port 3000)                  │
└─────────────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart              # API endpoints & configuration
│   ├── models/
│   │   └── user_model.dart              # User entity model
│   └── services/
│       ├── api_exception.dart           # Custom exception handling
│       └── token_storage_service.dart   # Secure token management
│
└── features/
    └── auth/
        ├── models/
        │   ├── auth_request_models.dart    # Request DTOs
        │   └── auth_response_models.dart   # Response DTOs
        ├── services/
        │   └── auth_api_service.dart       # HTTP API client
        └── screens/
            ├── signin_screen.dart          # Login UI
            ├── signup_screen.dart          # Registration UI
            └── verify_email_screen.dart    # Email verification UI
```

## Core Components

### 1. API Configuration (`api_config.dart`)

Centralized configuration for all API settings:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';
  static const Duration connectionTimeout = Duration(seconds: 30);
}
```

**Features:**
- Environment-based configuration
- Centralized endpoint management
- Default headers configuration
- Timeout settings

### 2. Data Models

#### Request Models (`auth_request_models.dart`)
- `RegisterRequest` - User registration data
- `LoginRequest` - Login credentials
- `VerifyEmailRequest` - Email verification code
- `ResendVerificationRequest` - Resend verification code
- `RefreshTokenRequest` - Token refresh
- `SupabaseLoginRequest` - OAuth login data

#### Response Models (`auth_response_models.dart`)
- `AuthResponse` - Authentication result with tokens
- `RegisterResponse` - Registration confirmation
- `VerificationResponse` - Verification status
- `LogoutResponse` - Logout confirmation

#### User Model (`user_model.dart`)
Core user entity with:
- Complete user profile data
- JSON serialization/deserialization
- Display name computation
- Immutable updates with `copyWith`

### 3. Services

#### AuthApiService (`auth_api_service.dart`)

HTTP client for backend communication with:

**Methods:**
- `register()` - Create new user account
- `login()` - Email/password authentication
- `supabaseLogin()` - OAuth authentication
- `verifyEmail()` - Verify email with code
- `resendVerification()` - Request new verification code
- `refreshToken()` - Refresh access token
- `logout()` - End user session

**Features:**
- Automatic error handling
- Network timeout management
- Response parsing
- Exception transformation

#### TokenStorageService (`token_storage_service.dart`)

Secure token persistence using SharedPreferences:

**Methods:**
- `saveTokens()` - Store authentication tokens
- `getAccessToken()` - Retrieve access token
- `getSessionToken()` - Retrieve session token
- `isAuthenticated()` - Check authentication status
- `clearTokens()` - Remove all tokens (logout)

**Security Notes:**
- Currently uses SharedPreferences
- For production: Consider `flutter_secure_storage`
- Tokens are stored locally for offline access

### 4. Exception Handling (`api_exception.dart`)

Unified error handling system:

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
}
```

**Factory Methods:**
- `fromResponse()` - Parse API error responses
- `networkError()` - Network connectivity issues
- `timeout()` - Request timeout
- `unauthorized()` - 401 authentication errors
- `serverError()` - 500 server errors

## Authentication Flow

### Registration Flow

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  SignUp     │─────>│  Backend     │─────>│  Database   │
│  Screen     │      │  /register   │      │  (Create)   │
└─────────────┘      └──────────────┘      └─────────────┘
       │                     │
       │                     ▼
       │            ┌──────────────┐
       └───────────>│  Verify      │
                    │  Email       │
                    │  Screen      │
                    └──────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  Home        │
                    │  Screen      │
                    └──────────────┘
```

**Steps:**
1. User fills registration form (email, password, names, phone)
2. Frontend validates input (password strength, phone format)
3. API call to `/auth/register`
4. Backend creates user with `isVerified: false`
5. Backend generates 6-digit verification code
6. Backend sends email with code (15-minute expiry)
7. User navigates to verification screen
8. User enters code
9. API call to `/auth/verify-email`
10. Backend verifies code and marks user as verified
11. Backend returns access token + session token
12. Frontend stores tokens
13. User navigates to home screen

### Login Flow

```
┌─────────────┐      ┌──────────────┐
│  SignIn     │─────>│  Backend     │
│  Screen     │      │  /login      │
└─────────────┘      └──────────────┘
       │                     │
       │              ┌──────▼──────┐
       │              │ Verified?   │
       │              └─────┬───────┘
       │                    │
       │         ┌──────────┴──────────┐
       │         │ Yes                 │ No
       │         ▼                     ▼
       │  ┌──────────┐        ┌────────────┐
       └─>│  Home    │        │  Verify    │
          │  Screen  │        │  Email     │
          └──────────┘        └────────────┘
```

**Steps:**
1. User enters email and password
2. API call to `/auth/login`
3. Backend validates credentials
4. **If verified:**
   - Returns access token + session token
   - Frontend stores tokens
   - Navigate to home
5. **If not verified:**
   - Returns `requiresVerification: true`
   - Navigate to verification screen
   - Follow verification flow

## Security Features

### Token Management

**Access Token (JWT):**
- Short-lived (10 minutes)
- RS256 signed with private key
- Contains: userId, email, sessionVersion
- Sent in Authorization header

**Session Token:**
- Long-lived (7 days)
- Opaque random token
- Argon2id hashed in database
- Used for token refresh

### Password Security

Frontend validation:
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character

Backend hashing:
- Argon2id algorithm
- 64MB memory cost
- 3 iterations
- Parallelism: 4 threads

### Email Verification

- 6-digit random code
- 15-minute expiry
- One-time use
- Required for first login
- Regenerated if expired

### Single Device Policy

- Backend invalidates old sessions on new login
- sessionVersion increments on each login
- Old access tokens become invalid

## API Endpoints

### Base URL
```
http://localhost:3000
```

### Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/register` | Register new user | No |
| POST | `/auth/login` | Email/password login | No |
| POST | `/auth/supabase-login` | OAuth login | No |
| POST | `/auth/verify-email` | Verify email code | No |
| POST | `/auth/resend-verification` | Resend code | No |
| POST | `/auth/refresh` | Refresh access token | No |
| POST | `/auth/logout` | Logout user | Yes |

## Environment Configuration

### Backend (.env)

```env
DATABASE_URL="postgresql://..."
JWT_PRIVATE_KEY_PATH="../private.pem"
JWT_PUBLIC_KEY_PATH="../public.pem"
JWT_ISSUER="cha9cha9ni-api"
JWT_AUDIENCE="cha9cha9ni-app"
ACCESS_TOKEN_TTL="10m"
SESSION_TTL_DAYS="7"
```

### Frontend

Update `ApiConfig.baseUrl` for different environments:

```dart
// Development
static const String baseUrl = 'http://localhost:3000';

// Production
static const String baseUrl = 'https://api.yourdomain.com';
```

## Error Handling

All API errors are caught and transformed into user-friendly messages:

```dart
try {
  await authApiService.login(request);
} on ApiException catch (e) {
  // Display e.message to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

**Common Errors:**
- `Invalid credentials` - Wrong email/password
- `Email already registered` - Duplicate registration
- `Invalid verification code` - Wrong code entered
- `Verification code expired` - Code timeout
- `Network error` - No internet connection
- `Server error` - Backend unavailable

## Best Practices Implemented

### 1. Separation of Concerns
- UI logic in screens
- Business logic in services
- Data structures in models
- Configuration in config files

### 2. Dependency Injection
- Services are instantiated in screens
- Easy to mock for testing
- No global state

### 3. Type Safety
- Strong typing throughout
- Null safety enabled
- Explicit error types

### 4. Code Reusability
- Shared models for request/response
- Common error handling
- Centralized configuration

### 5. User Experience
- Loading states for all async operations
- Clear error messages
- Offline handling
- Input validation

### 6. Security
- Tokens stored securely
- HTTPS recommended for production
- Password strength requirements
- Email verification mandatory

## Testing Recommendations

### Unit Tests
```dart
// Test models
test('UserModel.fromJson parses correctly', () {
  final json = {...};
  final user = UserModel.fromJson(json);
  expect(user.email, 'test@example.com');
});

// Test services
test('AuthApiService.login handles success', () async {
  final mockClient = MockClient();
  final service = AuthApiService(client: mockClient);
  // Test implementation
});
```

### Integration Tests
```dart
testWidgets('Login flow completes successfully', (tester) async {
  await tester.pumpWidget(MyApp());
  // Enter credentials
  // Tap login button
  // Verify navigation to home
});
```

## Future Enhancements

### Security
- [ ] Implement `flutter_secure_storage` for tokens
- [ ] Add biometric authentication
- [ ] Implement certificate pinning
- [ ] Add refresh token rotation

### Features
- [ ] Social login (Apple, Facebook)
- [ ] Two-factor authentication (2FA)
- [ ] Remember device functionality
- [ ] Password reset flow
- [ ] Profile management

### Architecture
- [ ] Implement BLoC/Riverpod for state management
- [ ] Add repository pattern
- [ ] Implement offline-first with local database
- [ ] Add analytics and crash reporting

## Troubleshooting

### Common Issues

**1. Connection Refused Error**
```
Solution: Ensure backend is running on port 3000
$ cd cha9cha9ni_back && npm start
```

**2. Tokens Not Persisting**
```
Solution: Check SharedPreferences initialization
Verify TokenStorageService.saveTokens is called after login
```

**3. Email Verification Not Working**
```
Solution: Check backend email service configuration
Verify verification code is not expired (15 min limit)
```

**4. CORS Errors (Web)**
```
Solution: Add CORS configuration in backend
app.enableCors({ origin: 'http://localhost:port' })
```

## Support

For questions or issues:
1. Check backend logs: `npm start` output
2. Check Flutter logs: `flutter run -v`
3. Review API responses in network inspector
4. Verify environment variables

---

**Last Updated:** January 2026
**Architecture Version:** 1.0.0
**Maintained By:** Development Team
