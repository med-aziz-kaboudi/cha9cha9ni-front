// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get firstName => 'First name *';

  @override
  String get lastName => 'Last name *';

  @override
  String get enterEmail => 'Enter your email *';

  @override
  String get phoneNumber => 'Phone number *';

  @override
  String get enterPassword => 'Enter your password *';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get orSignInWith => 'or sign in with';

  @override
  String get orSignUpWith => 'or sign up with';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get passwordRequirement1 => 'Must contain at least 8 characters';

  @override
  String get passwordRequirement2 => 'Contains a number';

  @override
  String get passwordRequirement3 => 'Contains an uppercase letter';

  @override
  String get passwordRequirement4 => 'Contains a special character';

  @override
  String get passwordStrong => 'Strong password!';

  @override
  String get passwordRequirements => 'Password requirements';

  @override
  String termsAgreement(String action) {
    return 'By clicking \"$action\" you agree to Cha9cha9ni ';
  }

  @override
  String get termOfUse => 'Term of Use ';

  @override
  String get and => 'and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get skip => 'Skip';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboarding1Title => 'Saving Works Better\nWhen We Do It\nTogether';

  @override
  String get onboarding1Description =>
      'Bring your family into one shared space and grow your savings step by step.';

  @override
  String get onboarding2Title => 'Save\nFor the Moments\nYou Care About';

  @override
  String get onboarding2Description =>
      'Thoughtful planning for meaningful moments, bringing peace and joy to your family.';

  @override
  String get otpVerification => 'OTP\nVerification';

  @override
  String get verifyEmailSubtitle => 'We need to verify your email';

  @override
  String get verifyEmailDescription =>
      'To verify your account, enter the 6 digit OTP code that we sent to your email.';

  @override
  String get verify => 'Verify';

  @override
  String get resendOTP => 'Resend OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendOTPIn(String seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get codeExpiresInfo => 'The code expires in 15 minutes';

  @override
  String get enterAllDigits => 'Please enter all 6 digits';

  @override
  String get emailVerifiedSuccess => '✅ Email verified successfully!';

  @override
  String verificationFailed(String error) {
    return 'Verification failed: $error';
  }

  @override
  String get verificationSuccess => 'Verification Success!';

  @override
  String get verificationSuccessSubtitle =>
      'Your email has been verified successfully. You can now access all features.';

  @override
  String get okay => 'Okay';

  @override
  String pleaseWaitSeconds(String seconds) {
    return 'Please wait $seconds seconds before requesting a new code';
  }

  @override
  String get emailAlreadyVerified => 'Email already verified';

  @override
  String get userNotFound => 'User not found';

  @override
  String get invalidVerificationCode => 'Invalid verification code';

  @override
  String get verificationCodeExpired =>
      'Verification code expired. Please request a new one.';

  @override
  String get noVerificationCode =>
      'No verification code found. Please request a new one.';

  @override
  String get registrationSuccessful =>
      'Registration successful! Please sign in to verify your email.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPassword => 'Enter your new password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordResetSuccessfully =>
      'Password reset successfully! You can now sign in with your new password.';

  @override
  String get checkYourMailbox => 'Check Your Mailbox';

  @override
  String weHaveSentResetCodeTo(String email) {
    return 'We have sent a 6-digit reset code to $email';
  }

  @override
  String get pleaseEnterEmail => 'Please enter your email address';

  @override
  String get invalidEmailFormat => 'Please enter a valid email address';

  @override
  String get pleaseEnterComplete6DigitCode =>
      'Please enter the complete 6-digit code';

  @override
  String get codeSentSuccessfully =>
      'Code sent successfully! Please check your email.';

  @override
  String get anErrorOccurred => 'An error occurred. Please try again.';

  @override
  String get didntReceiveCode => 'Didn\'t receive code?';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get joinOrCreateFamily => 'Join or Create a Family';

  @override
  String get chooseHowToProceed => 'Choose how you want to proceed';

  @override
  String get createAFamily => 'Create a Family';

  @override
  String get joinAFamily => 'Join a Family';

  @override
  String get enterInviteCode => 'XXXX-XXXX';

  @override
  String get pleaseEnterInviteCode => 'Please enter an invite code';

  @override
  String get failedToCreateFamily => 'Failed to create family';

  @override
  String get failedToJoinFamily => 'Failed to join family';

  @override
  String get joinNow => 'Join Now';

  @override
  String get cancel => 'Cancel';

  @override
  String get signOut => 'Sign Out';

  @override
  String get familyInviteCode => 'Family Invite Code';

  @override
  String get shareThisCode =>
      'Share this code with your family members so they can join your family.';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get codeCopied => 'Invite code copied to clipboard!';

  @override
  String get gotIt => 'Got it!';

  @override
  String get welcomeFamilyOwner => 'Welcome, Family Owner!';

  @override
  String get welcomeFamilyMember => 'Welcome, Family Member!';

  @override
  String get yourFamily => 'Your Family';

  @override
  String get owner => 'Owner';

  @override
  String get members => 'Members';

  @override
  String get noCodeAvailable => 'No code available';

  @override
  String get inviteCodeCopiedToClipboard => 'Invite code copied to clipboard!';

  @override
  String get shareCodeWithFamilyMembers =>
      'Share this code with family members.\nIt will change after each use.';

  @override
  String get scanButtonTapped => 'Scan button tapped';

  @override
  String get rewardScreenComingSoon => 'Reward screen coming soon';

  @override
  String get home => 'Home';

  @override
  String get reward => 'Reward';

  @override
  String get myFamily => 'My Family';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get yourCurrentPack => 'Your current pack';

  @override
  String get loginAndSecurity => 'Log in & security';

  @override
  String get languages => 'Languages';

  @override
  String get notifications => 'Notifications';

  @override
  String get help => 'Help';

  @override
  String get legalAgreements => 'Legal Agreements';

  @override
  String get logout => 'Logout';

  @override
  String get balance => 'Balance';

  @override
  String get topUp => 'Top up';

  @override
  String get withdraw => 'withdraw';

  @override
  String get statement => 'Statement';

  @override
  String get nextWithdrawal => 'Next Withdrawal';

  @override
  String availableInDays(int days) {
    return 'Available in $days days';
  }

  @override
  String get familyMembers => 'Family Members';

  @override
  String get manage => 'Manage >';

  @override
  String get recentActivities => 'Recent activities :';

  @override
  String get viewAll => 'View all  >';

  @override
  String get googleSignInCancelled => 'Sign In Cancelled';

  @override
  String get googleSignInCancelledMessage =>
      'You cancelled the Google sign in. Please try again to continue.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get close => 'Close';

  @override
  String get pts => 'pts';

  @override
  String get sessionExpiredTitle => 'Session Expired';

  @override
  String get sessionExpiredMessage =>
      'Another device has logged into your account. You will be signed out for security.';

  @override
  String get ok => 'OK';

  @override
  String get skipTutorial => 'Skip Guide';

  @override
  String get nextTutorial => 'Next';

  @override
  String get doneTutorial => 'Got it!';

  @override
  String get tutorialSidebarTitle => 'Menu';

  @override
  String get tutorialSidebarDesc =>
      'Tap here to open the sidebar menu. Access your profile, settings, and more options.';

  @override
  String get tutorialTopUpTitle => 'Top Up';

  @override
  String get tutorialTopUpDesc =>
      'Add money to your family account. Share funds with your family members easily.';

  @override
  String get tutorialWithdrawTitle => 'Withdraw';

  @override
  String get tutorialWithdrawDesc =>
      'Request to withdraw money from your family savings when you need it.';

  @override
  String get tutorialStatementTitle => 'Statement';

  @override
  String get tutorialStatementDesc =>
      'View all your transactions history. Track your family\'s spending and savings.';

  @override
  String get tutorialPointsTitle => 'Reward Points';

  @override
  String get tutorialPointsDesc =>
      'Earn points for every activity! Redeem them for exclusive rewards and benefits.';

  @override
  String get tutorialNotificationTitle => 'Notifications';

  @override
  String get tutorialNotificationDesc =>
      'Stay updated with family activities, transactions, and important alerts.';

  @override
  String get tutorialQrCodeTitle => 'QR Scanner';

  @override
  String get tutorialQrCodeDesc =>
      'Scan QR codes to make quick payments or add new family members.';

  @override
  String get tutorialRewardTitle => 'Rewards';

  @override
  String get tutorialRewardDesc =>
      'Explore and redeem your earned points for amazing rewards and discounts.';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get email => 'Email';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String get fullName => 'Full name';

  @override
  String get edit => 'Edit';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get verifyCurrentEmailDesc =>
      'To change your email, we first need to verify your current email address.';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String enterCodeSentTo(String email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String get currentEmailVerified => 'Current email verified';

  @override
  String get enterNewEmail => 'Enter your new email address';

  @override
  String get newEmailPlaceholder => 'newemail@example.com';

  @override
  String get confirmChange => 'Confirm Change';

  @override
  String get emailUpdatedSuccessfully => 'Email updated successfully!';

  @override
  String get phoneNumberMustBe8Digits =>
      'Phone number must be exactly 8 digits';

  @override
  String get phoneNumberAlreadyInUse => 'This phone number is already in use';

  @override
  String get addMember => 'Add Member';

  @override
  String get shareInviteCodeDesc =>
      'Share this code with your family member to add them';

  @override
  String get copy => 'Copy';

  @override
  String get noMembersYet => 'No members yet';

  @override
  String get tapAddMemberToInvite => 'Tap \"Add Member\" to invite your family';

  @override
  String get removeMember => 'Remove Member';

  @override
  String removeMemberConfirm(String name) {
    return 'Are you sure you want to remove $name from the family?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get confirmRemoval => 'Confirm Removal';

  @override
  String get enterCodeSentToEmail =>
      'Enter the verification code sent to your email';

  @override
  String get enterValidCode => 'Enter a valid 6-digit code';

  @override
  String removalInitiated(String name) {
    return 'Removal request sent to $name';
  }

  @override
  String get acceptRemoval => 'Accept Removal';

  @override
  String acceptRemovalConfirm(String name) {
    return '$name wants to remove you from the family. Do you accept?';
  }

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get confirmLeave => 'Confirm Leave';

  @override
  String get removedFromFamily => 'Removed from Family';

  @override
  String get removedFromFamilyDesc =>
      'You have been successfully removed from the family. You can now join or create a new family.';

  @override
  String get removalRequestTitle => 'Removal Request';

  @override
  String removalRequestDesc(String name) {
    return '$name wants to remove you from the family.';
  }

  @override
  String get viewRequest => 'View Request';

  @override
  String get verificationCodeWillBeSent =>
      'A verification code will be sent to your email';

  @override
  String get pendingRemovalRequests => 'Pending Removal Requests';

  @override
  String get cancelRemovalRequest => 'Cancel Request';

  @override
  String cancelRemovalConfirm(String name) {
    return 'Are you sure you want to cancel the removal request for $name?';
  }

  @override
  String get removalCancelled => 'Removal request cancelled';

  @override
  String get waitingForMemberConfirmation => 'Waiting for member confirmation';

  @override
  String get pendingRemoval => 'Pending';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get choosePreferredLanguage => 'Choose your preferred language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get currentLanguage => 'Current';

  @override
  String get loginSecurity => 'Login & Security';

  @override
  String get securityDescription =>
      'Add an extra layer of security to protect your account and family data.';

  @override
  String get passkey => 'Passkey';

  @override
  String get sixDigitPasskey => '6-Digit Passkey';

  @override
  String get passkeyEnabled => 'Enabled';

  @override
  String get passkeyNotSet => 'Not set up';

  @override
  String get passkeyEnabledDescription =>
      'Your account is protected with a 6-digit passkey.';

  @override
  String get passkeyDescription =>
      'Save this device for passwordless login. Like PayPal and Wise, you\'ll be able to log in instantly without entering your password.';

  @override
  String get setupPasskey => 'Set Up Passkey';

  @override
  String get changePasskey => 'Change';

  @override
  String get removePasskey => 'Remove Passkey';

  @override
  String get removePasskeyConfirm =>
      'This will also disable biometric authentication. You will need to set up a new passkey to re-enable security features.';

  @override
  String get verifyPasskey => 'Verify Passkey';

  @override
  String get enterPasskeyToRemove => 'Enter your passkey to confirm removal';

  @override
  String get currentPasskey => 'Current Passkey';

  @override
  String get enterCurrentPasskey => 'Enter your current passkey';

  @override
  String get newPasskey => 'New Passkey';

  @override
  String get enterNewPasskey => 'Enter your new 6-digit passkey';

  @override
  String get confirmPasskey => 'Confirm passkey';

  @override
  String get passkeyMustBe6Digits => 'Passkey must be 6 digits';

  @override
  String get passkeysDoNotMatch => 'Passkeys do not match';

  @override
  String get passkeySetupSuccess => 'Passkey set up successfully';

  @override
  String get passkeyChangedSuccess => 'Passkey changed successfully';

  @override
  String get passkeyRemovedSuccess => 'Security settings removed';

  @override
  String get faceId => 'Face ID';

  @override
  String get fingerprint => 'Fingerprint';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get biometricEnabled => 'Enabled';

  @override
  String get biometricDisabled => 'Disabled';

  @override
  String get biometricDescription =>
      'Use biometrics for quick and secure access. Falls back to passkey if biometric fails.';

  @override
  String get biometricsNotAvailable =>
      'Biometrics not available on this device';

  @override
  String get confirmBiometric => 'Confirm biometric to enable';

  @override
  String get biometricAuthFailed => 'Biometric authentication failed';

  @override
  String get howItWorks => 'How it works';

  @override
  String get securityStep1 =>
      'When you open the app, you\'ll be asked to verify your identity.';

  @override
  String get securityStep2 =>
      'First, biometric verification (Face ID / Fingerprint) is attempted if enabled.';

  @override
  String get securityStep3 =>
      'If biometric fails or is disabled, enter your 6-digit passkey.';

  @override
  String get securityStep4 =>
      'After 3 failed attempts, your account will be temporarily locked for your protection.';

  @override
  String get confirm => 'Confirm';

  @override
  String get unlockApp => 'Unlock App';

  @override
  String get enterPasskeyToUnlock => 'Enter your passkey to unlock';

  @override
  String attemptsRemaining(int count) {
    return '$count attempts remaining';
  }

  @override
  String get accountLocked => 'Account Locked';

  @override
  String accountLockedFor(String duration) {
    return 'Account locked for $duration';
  }

  @override
  String get accountPermanentlyLocked =>
      'Account permanently locked. Please contact support.';

  @override
  String tryAgainIn(String time) {
    return 'Try again in $time';
  }

  @override
  String useBiometric(String type) {
    return 'Use $type';
  }

  @override
  String get usePasskeyInstead => 'Use passkey instead';

  @override
  String get usePinInstead => 'Use PIN instead';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get pinCode => 'PIN Code';

  @override
  String get sixDigitPin => '6-Digit PIN';

  @override
  String get setupPinCode => 'Set Up PIN Code';

  @override
  String get setupPin => 'Set Up PIN';

  @override
  String get enterNewPin => 'Enter a 6-digit PIN to secure your account';

  @override
  String get pinSetupSuccess => 'PIN Code set up successfully';

  @override
  String get currentPin => 'Current PIN';

  @override
  String get enterCurrentPin => 'Enter your current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get changePin => 'Change';

  @override
  String get pinChangedSuccess => 'PIN changed successfully';

  @override
  String get removePin => 'Remove PIN Code';

  @override
  String get removePinConfirm =>
      'This will remove your PIN code. You can set up a new one anytime.';

  @override
  String get verifyPin => 'Verify PIN';

  @override
  String get enterPinToRemove => 'Enter your PIN to confirm removal';

  @override
  String get pinRemovedSuccess => 'PIN Code removed';

  @override
  String get pinMustBe6Digits => 'PIN must be 6 digits';

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get confirmPin => 'Confirm';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get pinEnabled => 'Enabled';

  @override
  String get pinNotSet => 'Not set up';

  @override
  String get pinEnabledDescription =>
      'Your account is protected with a 6-digit PIN.';

  @override
  String get pinDescription =>
      'Set up a 6-digit PIN as a backup method to unlock the app.';

  @override
  String get enterPinToUnlock => 'Enter your PIN to unlock';

  @override
  String get devicePasskey => 'Device Passkey';

  @override
  String get passkeyShortDesc => 'Passwordless device login';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get authenticatorApp => 'Authenticator App';

  @override
  String get twoFADescription =>
      'Use an authenticator app like Google Authenticator or Authy for additional security when logging in.';

  @override
  String get twoFAShortDesc => 'Google Authenticator, Authy';

  @override
  String get setup2FA => 'Set Up 2FA';

  @override
  String get pinRequiredForFaceId => 'Please set up PIN code first';

  @override
  String get requiresPinFirst => 'Requires PIN code';

  @override
  String get pinFirst => 'PIN first';

  @override
  String get securityInfoShort =>
      'Set up PIN code first, then enable Face ID for quick unlock. PIN is your backup if Face ID fails.';

  @override
  String get failedToSetupPin => 'Failed to set up PIN Code';

  @override
  String get failedToChangePin => 'Failed to change PIN';

  @override
  String get failedToRemovePin => 'Failed to remove PIN';

  @override
  String get failedToUpdateBiometric => 'Failed to update biometric settings';

  @override
  String get orDivider => 'OR';

  @override
  String get codeExpiresAfterUse => 'Code expires after first use';

  @override
  String get signInFailed => 'Sign in failed';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String get signOutFailed => 'Sign out failed';

  @override
  String get googleSignInFailed => 'Google sign in failed';

  @override
  String get googleSignUpFailed => 'Google sign up failed';

  @override
  String get reenterPinToConfirm => 'Re-enter your PIN to confirm';

  @override
  String get continueText => 'Continue';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get soon => 'Soon';

  @override
  String get featureComingSoon => 'This feature is coming soon!';

  @override
  String get useAnotherMethod => 'Use another method';

  @override
  String get unlockOptions => 'Unlock Options';

  @override
  String get chooseUnlockMethod => 'Choose how to unlock';

  @override
  String get tryFaceIdAgain => 'Try Face ID again';

  @override
  String get usePasskey => 'Use Passkey';

  @override
  String get use2FACode => 'Use 2FA Code';

  @override
  String get enter2FACode => 'Enter 2FA Code';

  @override
  String get enter6DigitCode => 'Enter 6-digit code from your app';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get invalidCode => 'Invalid code. Please try again.';

  @override
  String get twoFAEnabled => 'Enabled';

  @override
  String get twoFADisabled => '2FA disabled';

  @override
  String get disable => 'Disable';

  @override
  String get disable2FA => 'Disable 2FA';

  @override
  String get pinRequiredFor2FA => 'Please set up PIN code first';

  @override
  String get enterSixDigitCode => 'Please enter 6-digit code';

  @override
  String get enterCodeToDisable2FA =>
      'Enter the code from your authenticator app to confirm';

  @override
  String get twoFactorEnabled => 'Two-factor authentication enabled!';

  @override
  String get secretCopied => 'Secret key copied to clipboard';

  @override
  String get scanQrCode => 'Scan this QR code';

  @override
  String get useAuthenticatorApp =>
      'Open your authenticator app and scan this QR code to add your account';

  @override
  String get orText => 'OR';

  @override
  String get enterManually => 'Enter this key manually';

  @override
  String get copySecretKey => 'Copy secret key';

  @override
  String get authenticatorAccountInfo =>
      'The account name in your authenticator app will be your email address';

  @override
  String get enterVerificationCode => 'Enter Verification Code';

  @override
  String get enterCodeFromAuthenticator =>
      'Enter the 6-digit code from your authenticator app to complete setup';

  @override
  String get codeRefreshesEvery30Seconds =>
      'Codes refresh every 30 seconds. Make sure to enter the current code.';

  @override
  String get activateTwoFactor => 'Activate 2FA';

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get offlineMessage =>
      'Please check your internet connection and try again. You need to be connected to use this app.';

  @override
  String get connectionTip => 'Tip: Try enabling Wi-Fi or mobile data';

  @override
  String get closeApp => 'Close App';

  @override
  String get retryHint => 'App will automatically reconnect when online';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordDesc => 'Update your account password';

  @override
  String get changePasswordDialogDesc =>
      'Enter your current password and choose a new one';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get currentPasswordRequired => 'Current password is required';

  @override
  String get passwordDoesNotMeetRequirements =>
      'Password does not meet requirements';

  @override
  String get newPasswordMustBeDifferent =>
      'New password must be different from current password';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get failedToChangePassword => 'Failed to change password';

  @override
  String get createPassword => 'Create Password';

  @override
  String get createPasswordDesc => 'Create a password for your account';

  @override
  String get password => 'Password';

  @override
  String get passwordCreatedSuccess => 'Password created successfully';

  @override
  String get failedToCreatePassword => 'Failed to create password';

  @override
  String get alternativeUnlock => 'Alternative Unlock';

  @override
  String get chooseSecureMethod => 'Choose a secure method to unlock';

  @override
  String get authenticatorCode => 'Authenticator Code';
}
