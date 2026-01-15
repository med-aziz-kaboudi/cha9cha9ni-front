# Architecture Diagram

## Complete System Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                         FLUTTER FRONTEND                           │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    PRESENTATION LAYER                        │  │
│  │                                                              │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │  │
│  │  │  SignUp      │  │  SignIn      │  │  VerifyEmail    │  │  │
│  │  │  Screen      │  │  Screen      │  │  Screen         │  │  │
│  │  └──────┬───────┘  └──────┬───────┘  └────────┬────────┘  │  │
│  │         │                 │                    │           │  │
│  └─────────┼─────────────────┼────────────────────┼───────────┘  │
│            │                 │                    │              │
│  ┌─────────▼─────────────────▼────────────────────▼───────────┐  │
│  │                     SERVICE LAYER                           │  │
│  │                                                              │  │
│  │  ┌────────────────────┐        ┌──────────────────────┐   │  │
│  │  │  AuthApiService    │        │ TokenStorageService  │   │  │
│  │  │                    │        │                      │   │  │
│  │  │  • register()      │        │  • saveTokens()      │   │  │
│  │  │  • login()         │        │  • getAccessToken()  │   │  │
│  │  │  • verifyEmail()   │        │  • getSessionToken() │   │  │
│  │  │  • resendCode()    │        │  • clearTokens()     │   │  │
│  │  │  • refreshToken()  │        │  • isAuthenticated() │   │  │
│  │  │  • logout()        │        │                      │   │  │
│  │  └─────────┬──────────┘        └──────────────────────┘   │  │
│  │            │                                                │  │
│  └────────────┼────────────────────────────────────────────────┘  │
│               │                                                   │
│  ┌────────────▼───────────────────────────────────────────────┐  │
│  │                      DATA LAYER                             │  │
│  │                                                              │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │  │
│  │  │ UserModel    │  │ Requests     │  │ Responses    │     │  │
│  │  │              │  │              │  │              │     │  │
│  │  │ • id         │  │ • Register   │  │ • Auth       │     │  │
│  │  │ • email      │  │ • Login      │  │ • Register   │     │  │
│  │  │ • firstName  │  │ • Verify     │  │ • Verify     │     │  │
│  │  │ • lastName   │  │ • Resend     │  │ • Logout     │     │  │
│  │  │ • phone      │  │ • Refresh    │  │              │     │  │
│  │  │ • isVerified │  │              │  │              │     │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                               │                                   │
│                               │ HTTP/REST                         │
│                               │ (application/json)                │
└───────────────────────────────┼───────────────────────────────────┘
                                │
                                │
┌───────────────────────────────▼───────────────────────────────────┐
│                         NESTJS BACKEND                             │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    CONTROLLER LAYER                          │  │
│  │                                                              │  │
│  │  ┌───────────────────────────────────────────────────────┐  │  │
│  │  │              AuthController                           │  │  │
│  │  │                                                        │  │  │
│  │  │  POST /auth/register          • Validate DTO         │  │  │
│  │  │  POST /auth/login             • Return responses      │  │  │
│  │  │  POST /auth/verify-email      • Handle exceptions    │  │  │
│  │  │  POST /auth/resend-verification                       │  │  │
│  │  │  POST /auth/refresh                                   │  │  │
│  │  │  POST /auth/logout            [JWT Guard Protected]  │  │  │
│  │  └───────────────────┬───────────────────────────────────┘  │  │
│  │                      │                                       │  │
│  └──────────────────────┼───────────────────────────────────────┘  │
│                         │                                          │
│  ┌──────────────────────▼───────────────────────────────────────┐  │
│  │                    SERVICE LAYER                             │  │
│  │                                                              │  │
│  │  ┌───────────────────────────────────────────────────────┐  │  │
│  │  │              AuthService                              │  │  │
│  │  │                                                        │  │  │
│  │  │  • register()              → Hash password            │  │  │
│  │  │  • login()                 → Verify password          │  │  │
│  │  │  • verifyEmail()           → Check code & expiry      │  │  │
│  │  │  • resendVerification()    → Generate new code        │  │  │
│  │  │  • generateTokens()        → Create JWT + session     │  │  │
│  │  │  • generateAccessToken()   → Sign with RS256          │  │  │
│  │  │  • sendVerificationEmail() → Email service            │  │  │
│  │  └───────────────────┬───────────────────────────────────┘  │  │
│  │                      │                                       │  │
│  └──────────────────────┼───────────────────────────────────────┘  │
│                         │                                          │
│  ┌──────────────────────▼───────────────────────────────────────┐  │
│  │                    DATA LAYER                                │  │
│  │                                                              │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │  │
│  │  │ PrismaService│  │ JwtService   │  │ ConfigService│     │  │
│  │  │              │  │              │  │              │     │  │
│  │  │ • user       │  │ • sign()     │  │ • get()      │     │  │
│  │  │ • session    │  │ • verify()   │  │              │     │  │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘     │  │
│  │         │                                                   │  │
│  └─────────┼───────────────────────────────────────────────────┘  │
│            │                                                      │
└────────────┼──────────────────────────────────────────────────────┘
             │
             │ Prisma Client
             │
┌────────────▼──────────────────────────────────────────────────────┐
│                      POSTGRESQL DATABASE                          │
│                                                                    │
│  ┌──────────────────────┐          ┌──────────────────────┐      │
│  │   User Table         │          │   Session Table      │      │
│  │                      │          │                      │      │
│  │  • id                │          │  • id                │      │
│  │  • email (unique)    │          │  • userId            │      │
│  │  • passwordHash      │◄─────────┤  • tokenHash         │      │
│  │  • firstName         │          │  • expiresAt         │      │
│  │  • lastName          │          │  • createdAt         │      │
│  │  • phone             │          │                      │      │
│  │  • isVerified        │          └──────────────────────┘      │
│  │  • verificationCode  │                                        │
│  │  • verificationExpiry│                                        │
│  │  • sessionVersion    │                                        │
│  │  • createdAt         │                                        │
│  │  • updatedAt         │                                        │
│  └──────────────────────┘                                        │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Data Flow Examples

### 1. Registration Flow

```
User Input (SignUpScreen)
    │
    ├─ firstName: "John"
    ├─ lastName: "Doe"
    ├─ email: "john@example.com"
    ├─ password: "Secure123!"
    └─ phone: "+21612345678"
    │
    ▼
AuthApiService.register(RegisterRequest)
    │
    │ HTTP POST /auth/register
    │ Content-Type: application/json
    │ {
    │   "firstName": "John",
    │   "lastName": "Doe",
    │   "email": "john@example.com",
    │   "password": "Secure123!",
    │   "phone": "+21612345678"
    │ }
    │
    ▼
AuthController.register()
    │
    ├─ Validate DTO
    └─ Call AuthService.register()
        │
        ├─ Check email exists
        ├─ Hash password (Argon2id)
        ├─ Generate 6-digit code
        ├─ Calculate expiry (15 min)
        ├─ Create user in DB
        └─ Send verification email
        │
        ▼
    RegisterResponse {
      "id": "uuid",
      "email": "john@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "phone": "+21612345678",
      "message": "Registration successful...",
      "createdAt": "2026-01-11T..."
    }
    │
    ▼
Navigate to VerifyEmailScreen
Display success message
```

### 2. Login Flow (Verified User)

```
User Input (SignInScreen)
    │
    ├─ email: "john@example.com"
    └─ password: "Secure123!"
    │
    ▼
AuthApiService.login(LoginRequest)
    │
    │ HTTP POST /auth/login
    │ {
    │   "email": "john@example.com",
    │   "password": "Secure123!"
    │ }
    │
    ▼
AuthController.login()
    │
    └─ Call AuthService.login()
        │
        ├─ Find user by email
        ├─ Verify password (Argon2)
        ├─ Check isVerified = true ✓
        ├─ Delete old sessions (single device)
        ├─ Increment sessionVersion
        ├─ Generate tokens:
        │   ├─ Access Token (JWT, 10min)
        │   └─ Session Token (random, 7 days)
        └─ Store session in DB (hashed)
        │
        ▼
    AuthResponse {
      "accessToken": "eyJhbGciOi...",
      "sessionToken": "abc123...",
      "expiresIn": "10m",
      "user": {
        "id": "uuid",
        "email": "john@example.com",
        "fullName": "John Doe"
      }
    }
    │
    ▼
TokenStorageService.saveTokens()
    │
    ├─ Store accessToken
    ├─ Store sessionToken
    ├─ Store expiresIn
    └─ Store userId
    │
    ▼
Navigate to HomeScreen
```

### 3. Login Flow (Unverified User)

```
User Input (SignInScreen)
    │
    ├─ email: "jane@example.com"
    └─ password: "Secure123!"
    │
    ▼
AuthApiService.login(LoginRequest)
    │
    ▼
AuthController.login()
    │
    └─ Call AuthService.login()
        │
        ├─ Find user by email
        ├─ Verify password (Argon2)
        ├─ Check isVerified = false ✗
        ├─ Check if code expired
        ├─ Generate new code (if needed)
        ├─ Update user in DB
        └─ Send verification email
        │
        ▼
    AuthResponse {
      "requiresVerification": true,
      "email": "jane@example.com",
      "message": "Please check your email..."
    }
    │
    ▼
Navigate to VerifyEmailScreen
Display verification required message
```

### 4. Email Verification Flow

```
User Input (VerifyEmailScreen)
    │
    ├─ email: "jane@example.com"
    └─ code: "123456"
    │
    ▼
AuthApiService.verifyEmail(VerifyEmailRequest)
    │
    │ HTTP POST /auth/verify-email
    │ {
    │   "email": "jane@example.com",
    │   "code": "123456"
    │ }
    │
    ▼
AuthController.verifyEmail()
    │
    └─ Call AuthService.verifyEmail()
        │
        ├─ Find user by email
        ├─ Check isVerified = false
        ├─ Check code exists
        ├─ Check code not expired
        ├─ Compare code (string match)
        ├─ Update user:
        │   ├─ isVerified = true
        │   ├─ verificationCode = null
        │   └─ verificationCodeExpiry = null
        ├─ Delete old sessions
        ├─ Increment sessionVersion
        └─ Generate tokens
        │
        ▼
    AuthResponse {
      "accessToken": "eyJhbGciOi...",
      "sessionToken": "xyz789...",
      "expiresIn": "10m",
      "user": {...}
    }
    │
    ▼
TokenStorageService.saveTokens()
    │
    ▼
Navigate to HomeScreen
Display success message
```

## Security Flow

### Token Generation & Validation

```
┌─────────────────────────────────────────────────────────────────┐
│                    ACCESS TOKEN (JWT)                           │
│                                                                 │
│  Header:                                                        │
│  {                                                              │
│    "alg": "RS256",          ← Asymmetric algorithm             │
│    "typ": "JWT"                                                 │
│  }                                                              │
│                                                                 │
│  Payload:                                                       │
│  {                                                              │
│    "sub": "user-id",         ← User identifier                 │
│    "email": "user@email.com",                                   │
│    "ver": 1,                 ← Session version (invalidation)  │
│    "iat": 1673456789,        ← Issued at                       │
│    "exp": 1673457389,        ← Expires (10 min)                │
│    "iss": "cha9cha9ni-api",  ← Issuer                          │
│    "aud": "cha9cha9ni-app"   ← Audience                        │
│  }                                                              │
│                                                                 │
│  Signature:                                                     │
│  RSASHA256(                                                     │
│    base64UrlEncode(header) + "." +                              │
│    base64UrlEncode(payload),                                    │
│    privateKey                 ← Stored in private.pem          │
│  )                                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   SESSION TOKEN (Opaque)                        │
│                                                                 │
│  Generation:                                                    │
│  crypto.randomBytes(48)      ← 48 random bytes                 │
│    .toString('base64url')    ← URL-safe encoding               │
│                                                                 │
│  Storage in DB:                                                 │
│  argon2.hash(sessionToken)   ← Hashed with Argon2id           │
│                                                                 │
│  Verification:                                                  │
│  argon2.verify(              ← Compare stored hash             │
│    storedHash,                  with incoming token            │
│    incomingToken                                                │
│  )                                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        Error Hierarchy                          │
│                                                                 │
│  HTTP Layer                                                     │
│  ├─ Network Errors                                              │
│  │  ├─ SocketException         → "Network error. Check..."    │
│  │  ├─ ClientException         → "Network error. Check..."    │
│  │  └─ TimeoutException        → "Request timeout..."         │
│  │                                                              │
│  ├─ Response Errors                                             │
│  │  ├─ 400 Bad Request         → Parse message from body      │
│  │  ├─ 401 Unauthorized        → "Unauthorized. Please..."    │
│  │  ├─ 409 Conflict            → "Email already registered"   │
│  │  └─ 500 Server Error        → "Server error. Try..."       │
│  │                                                              │
│  └─ Parse Errors                                                │
│     └─ JSON Decode Error       → "Failed to parse response"   │
│                                                                 │
│  Application Layer                                              │
│  ├─ Validation Errors                                           │
│  │  ├─ Empty fields            → "Please enter..."            │
│  │  ├─ Invalid email           → "Invalid email format"       │
│  │  ├─ Weak password           → "Password must contain..."   │
│  │  └─ Invalid code            → "Code must be 6 digits"      │
│  │                                                              │
│  └─ Business Logic Errors                                       │
│     ├─ Duplicate email         → "Email already registered"    │
│     ├─ Invalid credentials     → "Invalid credentials"         │
│     ├─ Expired code            → "Verification code expired"   │
│     └─ Invalid code            → "Invalid verification code"   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Error Display:
    │
    ▼
ScaffoldMessenger.showSnackBar()
    │
    ├─ Red background for errors
    ├─ Green background for success
    └─ Orange background for warnings
```

---

**This diagram shows the complete end-to-end architecture of your authentication system!**
