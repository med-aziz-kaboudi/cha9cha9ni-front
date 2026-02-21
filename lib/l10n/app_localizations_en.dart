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
  String get emailVerifiedSuccess => 'Email verified successfully!';

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
  String get enterInviteCode => 'Enter Redemption Code';

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
  String get you => 'You';

  @override
  String get member => 'Member';

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
  String get yourCurrentPack => 'Your Current Pack';

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
  String get leaveFamily => 'Leave Family';

  @override
  String get logout => 'Logout';

  @override
  String get balance => 'Balance';

  @override
  String get topUp => 'Top up';

  @override
  String get topUpCreditCard => 'Credit Card';

  @override
  String get topUpCreditCardDesc =>
      'Pay securely with your credit or debit card';

  @override
  String get topUpPayWithCard => 'Pay with Card';

  @override
  String get topUpScratchCard => 'Scratch Card';

  @override
  String get topUpScratchCardDesc =>
      'Redeem your scratch card code to add funds';

  @override
  String get topUpRedeemCard => 'Redeem Card';

  @override
  String get topUpCurrentBalance => 'Current Balance';

  @override
  String get topUpFeeNotice =>
      'Service fees of 5% apply on credit card purchases';

  @override
  String get topUpChooseMethod => 'Choose Payment Method';

  @override
  String get topUpEnterCode => 'Enter Scratch Card Code';

  @override
  String get topUpEnterCodeDesc =>
      'Scratch the back of your card to reveal the code and enter it below';

  @override
  String get topUpSuccess => 'Top Up Successful!';

  @override
  String get topUpPointsEarned => 'points earned';

  @override
  String get topUpNewBalance => 'New balance';

  @override
  String get topUpScanQR => 'Or scan QR code';

  @override
  String get withdraw => 'Withdraw';

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
  String get viewAll => 'View all';

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
  String get nameLockedAfterVerification => 'Verified';

  @override
  String get accountAlreadyVerifiedWithId =>
      'This identity document is already linked to another account.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get changeProfilePhoto => 'Change Profile Photo';

  @override
  String get tapOptionToChange => 'Tap an option below to update your photo';

  @override
  String get addPhotoDescription => 'Add a photo to personalize your profile';

  @override
  String get useCamera => 'Take a new photo now';

  @override
  String get browsePhotos => 'Select from your photo library';

  @override
  String get deleteCurrentPhoto => 'Remove your current profile photo';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully!';

  @override
  String get profilePictureRemoved => 'Profile picture removed successfully!';

  @override
  String get removeProfilePictureConfirmation =>
      'Are you sure you want to remove your profile picture? You can add a new one after 24 hours.';

  @override
  String profilePictureRateLimitWarning(String time) {
    return 'You can change your photo again in $time';
  }

  @override
  String get remove => 'Remove';

  @override
  String get cropPhoto => 'Crop Photo';

  @override
  String get done => 'Done';

  @override
  String get cannotRemoveProfilePicture =>
      'To remove your profile picture, please contact support';

  @override
  String get photoPermissionDenied =>
      'Photo access permission denied. Please enable it in Settings.';

  @override
  String get uploadFailed => 'Failed to upload image. Please try again.';

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

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get noNotificationsDesc => 'You\'ll see important updates here';

  @override
  String get allNotificationsRead => 'All notifications marked as read';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get setupSecurity => 'Setup Security';

  @override
  String get viewDetails => 'View Details';

  @override
  String get notificationWelcomeTitle => 'Welcome to Cha9cha9ni';

  @override
  String get notificationWelcomeMessage =>
      'We\'re excited to have you join our community! If you need any help, don\'t hesitate to contact our support team at support@cha9cha9ni.tn or use the Help option in the menu.';

  @override
  String get notificationProfileTitle => 'Complete Your Profile';

  @override
  String get notificationProfileMessage =>
      'To make withdrawals and access all our features, please complete your personal information in your profile settings. This helps us verify your identity and keep your account secure.';

  @override
  String get notificationSecurityTitle => 'Secure Your Account';

  @override
  String get notificationSecurityMessage =>
      'Protect your account by enabling two-factor authentication (2FA) and setting up a PIN code. This will help safeguard your data and transactions from unauthorized access.';

  @override
  String get read => 'Read';

  @override
  String get noRecentActivities => 'No recent activities';

  @override
  String get wantsToRemoveYou => 'Wants to remove';

  @override
  String ownerRequestedRemoval(String ownerName) {
    return '$ownerName has requested to remove you from the family';
  }

  @override
  String get respond => 'Respond';

  @override
  String get signingYouIn => 'Signing you in...';

  @override
  String get justNow => 'Just now';

  @override
  String minAgo(int count) {
    return '$count min ago';
  }

  @override
  String minsAgo(int count) {
    return '$count mins ago';
  }

  @override
  String hourAgo(int count) {
    return '$count hour ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String dayAgo(int count) {
    return '$count day ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String monthAgo(int count) {
    return '$count month ago';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get scanCode => 'Redeem Gift Card';

  @override
  String get cameraPermissionRequired => 'Camera Permission Required';

  @override
  String get cameraPermissionDescription =>
      'We need camera access to scan gift card codes and QR codes.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get pointCameraAtCode => 'Point camera at gift card code';

  @override
  String get enterCodeManually => 'Enter Code Manually';

  @override
  String get scanInstead => 'Scan Instead';

  @override
  String get enterCodeDescription =>
      'Enter the gift card code to add balance to your account';

  @override
  String get invalidCodeFormat => 'Please enter a valid redemption code';

  @override
  String get codeScanned => 'Code Scanned!';

  @override
  String get joinFamily => 'Redeem';

  @override
  String get rewardsPoints => 'points';

  @override
  String get rewardsStreak => 'Streak';

  @override
  String get rewardsAds => 'Ads';

  @override
  String get rewardsDailyCheckIn => 'Daily Check-in';

  @override
  String rewardsDayStreak(int count) {
    return '$count day streak!';
  }

  @override
  String rewardsClaimPoints(int points) {
    return 'Claim +$points pts';
  }

  @override
  String get rewardsClaimed => 'Claimed';

  @override
  String get rewardsNextIn => 'Next in';

  @override
  String get rewardsWatchAndEarn => 'Watch & Earn';

  @override
  String rewardsWatchAdToEarn(int points) {
    return 'Watch ad to earn +$points pts';
  }

  @override
  String get rewardsAllAdsWatched => 'All ads watched today!';

  @override
  String get rewardsRedeemRewards => 'Redeem Rewards';

  @override
  String get rewardsConvertPoints => 'Convert points to TND';

  @override
  String get rewardsRedeem => 'Redeem';

  @override
  String get rewardsComingSoon => 'Coming Soon!';

  @override
  String rewardsRedeemingFor(String name, String points) {
    return 'Redeeming $name for $points points will be available soon!';
  }

  @override
  String get rewardsGotIt => 'Got it!';

  @override
  String get rewardsSimulatedAd => 'Simulated Ad';

  @override
  String get rewardsSimulatedAdDesc =>
      'In production, a real rewarded ad would play here.';

  @override
  String get rewardsSkipAd => 'Skip Ad';

  @override
  String get rewardsWatchComplete => 'Watch Complete';

  @override
  String get rewardsPointsEarned => 'Points earned!';

  @override
  String get rewardsAdReward => 'Ad Reward';

  @override
  String get rewardsDailyReward => 'Daily Reward';

  @override
  String get rewardsLoadingAd => 'Loading ad...';

  @override
  String get rewardsCheckInSuccess => 'Check-in successful!';

  @override
  String get rewardsCheckInFailed => 'Check-in failed. Please try again.';

  @override
  String get rewardsClaimFailed => 'Failed to claim reward. Please try again.';

  @override
  String get rewardsAdFailed => 'Ad failed to show. Please try again.';

  @override
  String get rewardsConfirmRedeem => 'Confirm Redemption';

  @override
  String get rewardsCurrentPoints => 'Current Points';

  @override
  String get rewardsPointsToSpend => 'Points to Spend';

  @override
  String get rewardsRemainingPoints => 'Remaining Points';

  @override
  String get rewardsToBalance => 'to balance';

  @override
  String get rewardsCongratulations => 'Congratulations!';

  @override
  String get rewardsAddedToBalance => 'Added to your balance';

  @override
  String get rewardsNewBalance => 'New Balance';

  @override
  String rewardsRedemptionSuccess(String points, String amount) {
    return 'Successfully redeemed $points points for $amount TND';
  }

  @override
  String get rewardsRedemptionFailed => 'Redemption failed. Please try again.';

  @override
  String get tapToDismiss => 'Tap to dismiss';

  @override
  String get allActivities => 'All Activities';

  @override
  String get activitiesWillAppearHere =>
      'Family activities will appear here when members earn points';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String activityWatchedAd(String name) {
    return '$name watched an ad';
  }

  @override
  String activityDailyCheckIn(String name) {
    return '$name claimed daily check-in';
  }

  @override
  String activityTopUp(String name) {
    return '$name topped up';
  }

  @override
  String activityReferral(String name) {
    return '$name referral bonus';
  }

  @override
  String activityRedemption(String name) {
    return '$name redeemed points';
  }

  @override
  String activityEarnedPoints(String name) {
    return '$name earned points';
  }

  @override
  String get filterActivities => 'Filter Activities';

  @override
  String get filterByTime => 'By Time Period';

  @override
  String get filterByType => 'By Activity Type';

  @override
  String get filterByMember => 'Filter by Member';

  @override
  String get showOnlyMyActivities => 'Show only my activities';

  @override
  String get filterAll => 'All';

  @override
  String get filterLast10Days => 'Last 10 days';

  @override
  String get filterLast7Days => 'Last 7 days';

  @override
  String get filterLast30Days => 'Last 30 days';

  @override
  String get filterLast3Months => 'Last 3 months';

  @override
  String get filterAllTypes => 'All Types';

  @override
  String get filterAds => 'Ads';

  @override
  String get filterCheckIn => 'Check-in';

  @override
  String get filterTopUp => 'Top Up';

  @override
  String get filterReferral => 'Referral';

  @override
  String get filterRedemption => 'Redemption';

  @override
  String get filterOther => 'Other';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get noActivitiesForFilter => 'No activities match your filters';

  @override
  String get usageAndLimits => 'Usage and Limits';

  @override
  String ownerPlusMembers(int count) {
    return 'Owner + $count members';
  }

  @override
  String get withdrawAccess => 'Withdraw Access';

  @override
  String get ownerOnlyCanWithdraw => 'Owner only can withdraw';

  @override
  String get youAreOwner => 'You are the family owner';

  @override
  String get onlyOwnerCanWithdrawDescription =>
      'Only the family owner can withdraw funds';

  @override
  String get kycVerified => 'Identity verified';

  @override
  String get kycRequired => 'KYC verification required to withdraw';

  @override
  String get verifyIdentity => 'Verify Identity';

  @override
  String get selectedAid => 'Selected Aid';

  @override
  String get selectAnAid => 'Tap to select an aid';

  @override
  String maxDT(int amount) {
    return 'Max $amount DT';
  }

  @override
  String get adsToday => 'Ads Today';

  @override
  String adsPerMember(int count) {
    return '$count ads / member';
  }

  @override
  String get watched => 'watched';

  @override
  String get adsDescription =>
      'Watch ads to earn points for your family savings';

  @override
  String get unlockMoreBenefits =>
      'Upgrade your pack to unlock more benefits, higher withdrawals and more aids';

  @override
  String get changeMyPack => 'Change my pack';

  @override
  String get free => 'Free';

  @override
  String get month => 'month';

  @override
  String get year => 'year';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String upToAmount(int amount) {
    return 'Up to $amount DT total';
  }

  @override
  String withdrawalsPerYear(int count) {
    return '$count withdrawals / year';
  }

  @override
  String get allPacks => 'All Packs';

  @override
  String get choosePack => 'Choose Your Pack';

  @override
  String get choosePackDescription =>
      'Select the pack that best fits your family\'s needs';

  @override
  String minimumWithdrawal(int amount) {
    return 'Minimum withdrawal amount is $amount DT';
  }

  @override
  String familyMembersCount(int count) {
    return '$count family members';
  }

  @override
  String aidsSelectable(int count) {
    return '$count aids selectable';
  }

  @override
  String get currentPack => 'Current Pack';

  @override
  String get selectPack => 'Select Pack';

  @override
  String upgradeTo(String name) {
    return 'Upgrade to $name';
  }

  @override
  String downgradeTo(String name) {
    return 'Downgrade to $name';
  }

  @override
  String get downgradeConfirmation =>
      'Are you sure you want to switch to the Free pack? You may lose access to some features.';

  @override
  String upgradeConfirmation(String name, int price) {
    return 'Upgrade to $name for $price DT/month?';
  }

  @override
  String get confirmSelection => 'Confirm Selection';

  @override
  String get subscriptionComingSoon => 'Subscription management coming soon!';

  @override
  String get selectAid => 'Select Aid';

  @override
  String get tunisianAids => 'Tunisian Aids';

  @override
  String selectionsRemaining(int remaining, int total) {
    return '$remaining of $total selections available';
  }

  @override
  String get aidSelectionDescription =>
      'Select your preferred aid for withdrawal. Each aid has specific withdrawal windows and maximum amounts.';

  @override
  String get aidSelectionHint =>
      'The amount shown is the maximum you can withdraw during this aid\'s window period after selecting it.';

  @override
  String get packBasedWithdrawalHint =>
      'Upgrade your pack to unlock higher withdrawal limits and select more aids!';

  @override
  String get withdrawalLimit => 'You can withdraw up to';

  @override
  String get limitReached => 'Limit reached';

  @override
  String get yourSelectedAids => 'Your Selected Aids';

  @override
  String get availableAids => 'Available Aids';

  @override
  String get selected => 'Selected';

  @override
  String get maxWithdrawal => 'Max withdrawal';

  @override
  String get window => 'Window';

  @override
  String get select => 'Select';

  @override
  String get aidAlreadySelected => 'This aid is already selected';

  @override
  String maxAidsReached(int count) {
    return 'You can only select $count aid(s) with your current pack';
  }

  @override
  String get selectAidConfirmTitle => 'Confirm Aid Selection';

  @override
  String selectAidConfirmMessage(String name) {
    return 'Are you sure you want to select $name?';
  }

  @override
  String get aidSelectionWarning =>
      'You cannot change your selected aid without contacting support';

  @override
  String aidSelectedSuccess(String name) {
    return '$name has been selected successfully';
  }

  @override
  String get saveForNextYear => 'Save for Next Year';

  @override
  String selectForYear(int year) {
    return 'For $year';
  }

  @override
  String nextYearWithdrawalInfo(int year) {
    return 'Withdrawal available in $year';
  }

  @override
  String get savingForNextYearHint =>
      'This aid\'s deadline for this year has passed. Select now to save for next year!';

  @override
  String get deadlinePassed => 'Deadline Passed';

  @override
  String get viewOnlyPackInfo =>
      'Only the family owner can manage pack and aids';

  @override
  String get noAidSelected => 'No aid selected yet';

  @override
  String get tapToViewAids => 'Tap to view upcoming aids';

  @override
  String daysUntilAid(int days, String aidName) {
    return '$days days until $aidName';
  }

  @override
  String get aidWindowOpen => 'Withdrawal window is open!';

  @override
  String aidWindowClosed(int days) {
    return 'Window opens in $days days';
  }

  @override
  String get leaveFamilyTitle => 'Leave Family';

  @override
  String get leaveFamilyConfirmMessage =>
      'Are you sure you want to leave this family? Your points will stay with your current family and you will start fresh if you join a new one.';

  @override
  String get leaveFamilyWarning => 'This action cannot be undone';

  @override
  String get leave => 'Leave';

  @override
  String get leaveFamilyCodeSent => 'Confirmation code sent to your email';

  @override
  String get leaveFamilySuccess => 'You have successfully left the family';

  @override
  String get leaveFamilyConfirmTitle => 'Confirm Leave';

  @override
  String get leaveFamilyCodePrompt =>
      'Enter the 6-digit code sent to your email to confirm leaving the family';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get resendCodeIn => 'Resend code in';

  @override
  String get codeSentAgain => 'Code sent again';

  @override
  String tooManyAttempts(Object minutes) {
    return 'Too many attempts. Please try again in $minutes minutes.';
  }

  @override
  String get tooManyAttemptsTitle => 'Too Many Attempts';

  @override
  String rateLimitedWait(String time) {
    return 'Rate limited. Please wait $time';
  }

  @override
  String tooManyRefreshes(int minutes) {
    return 'Too many refreshes. Please wait $minutes minutes.';
  }

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get statementTitle => 'Statement';

  @override
  String get statementSubtitle =>
      'Select a start date to generate your statement and receive it via email';

  @override
  String get statementSelectStartDate => 'Select Start Date';

  @override
  String get statementDateHint => 'Statement from this date to today';

  @override
  String get statementYear => 'Year';

  @override
  String get statementMonth => 'Month';

  @override
  String get statementPeriod => 'Statement Period';

  @override
  String get statementToday => 'Today';

  @override
  String get statementSelectDate => 'Please select a date';

  @override
  String get statementNoActivity =>
      'No activity found for this period. Please select another date.';

  @override
  String get statementLoadError => 'Failed to load data. Please try again.';

  @override
  String get statementGenerateError =>
      'Failed to generate statement. Please try again.';

  @override
  String get statementSending => 'Sending...';

  @override
  String get statementSendButton => 'Send to My Email';

  @override
  String get statementRateLimitError =>
      'Limit reached! You can only send 2 statements per day.';

  @override
  String get statementRateLimitNote => 'Limited to 2 sends per day';

  @override
  String statementRemainingEmails(int count) {
    return '$count send(s) remaining today';
  }

  @override
  String get statementSentTitle => 'Statement Sent!';

  @override
  String statementSentDescription(String startDate) {
    return 'Your statement from $startDate to today has been sent to';
  }

  @override
  String get statementGotIt => 'Got it!';

  @override
  String get transferOwnership => 'Transfer Ownership';

  @override
  String get transferOwnershipBlocked => 'Transfer Blocked';

  @override
  String get transferOwnershipBlockedDesc =>
      'Ownership transfer is no longer available after a withdrawal';

  @override
  String get transferOwnershipWithdrawalNote =>
      'Once a withdrawal is made, ownership transfer is permanently disabled for KYC compliance.';

  @override
  String get transferOwnershipWarning =>
      'Warning: This action is irreversible. The new owner will have full control of the family.';

  @override
  String get selectNewOwner => 'Select the new owner';

  @override
  String get noEligibleMembers => 'No eligible members for transfer';

  @override
  String get continueButton => 'Continue';

  @override
  String get verifyTransfer => 'Verify Transfer';

  @override
  String get transferCodeSent =>
      'A verification code has been sent to your email';

  @override
  String get transferringTo => 'Transferring to';

  @override
  String get confirmTransfer => 'Confirm Transfer';

  @override
  String get ownershipTransferredSuccess =>
      'Ownership transferred successfully';

  @override
  String withdrawWindowLabel(String startDate, String endDate) {
    return 'Withdraw from $startDate to $endDate';
  }

  @override
  String aidDateLabel(String date) {
    return 'Aid date: $date';
  }

  @override
  String selectionDeadlineLabel(String date) {
    return 'Select before $date';
  }

  @override
  String maxWithdrawAmount(int amount) {
    return 'Max: $amount DT';
  }

  @override
  String get withdrawWindowOpen => 'Withdrawal window open!';

  @override
  String daysUntilWithdrawOpen(int days) {
    return '$days days until withdrawal opens';
  }

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get cancelVerification => 'Cancel Verification';

  @override
  String get cancelVerificationMessage =>
      'Are you sure you want to cancel the verification process?';

  @override
  String get verificationError => 'Verification error occurred';

  @override
  String get verificationInProgress => 'Verification in progress...';

  @override
  String get identityVerified => 'Identity verified';

  @override
  String get verifyIdentityDescription =>
      'Verify your identity to enable additional features';

  @override
  String get transferOwnershipContactSupport =>
      'Your identity is verified. Please contact support to transfer ownership.';

  @override
  String get sessionExpiredGoBack =>
      'Session expired. Please go back and try again.';

  @override
  String get memberFallback => 'Member';

  @override
  String get transferCancelled => 'Transfer cancelled';

  @override
  String get newCodeSentEmail => 'New code sent to your email';

  @override
  String get resend => 'Resend';

  @override
  String get verifiedAccountTitle => 'Verified Account';

  @override
  String get verificationUnderReviewTitle => 'Verification Under Review';

  @override
  String get verifiedIdentityTransferDesc =>
      'Your identity has been verified. To transfer ownership, please contact our support team.';

  @override
  String get verificationUnderReviewTransferDesc =>
      'Your identity verification is under review. Please wait for the result before transferring ownership.';

  @override
  String get transferRateLimitExceededDesc =>
      'You have reached the maximum number of ownership transfers. Please wait before transferring again.';

  @override
  String get verifiedAccountSecurityNote =>
      'For security reasons, verified accounts require support assistance to transfer ownership.';

  @override
  String get verificationPendingNote =>
      'Verification usually takes a few minutes. You will be notified once complete.';

  @override
  String get transferLimitReached => 'Transfer Limit Reached';

  @override
  String transferLimitReachedDesc(String displayTime) {
    return 'You have reached the maximum of 2 ownership transfers per month. Please try again in $displayTime.';
  }

  @override
  String get transferLimitSecurityNote =>
      'This limit helps prevent abuse and ensures security for all family members.';

  @override
  String get tooManyTransferAttemptsNote =>
      'You have made too many transfer attempts. Please wait before trying again.';

  @override
  String get pendingTransferTitle => 'Pending Transfer';

  @override
  String pendingTransferDesc(String name) {
    return 'You have a pending transfer to $name. Enter the code received by email to confirm, or cancel the transfer.';
  }

  @override
  String get withdrawVerifyTitle => 'Verify Your Identity';

  @override
  String get withdrawVerifySubtitle =>
      'Identity verification is required before you can withdraw funds. It only takes a minute.';

  @override
  String get withdrawStep1Title => 'Verify Your ID';

  @override
  String get withdrawStep1Desc =>
      'Submit your government-issued ID for a quick verification.';

  @override
  String get withdrawStep2Title => 'Wait for Approval';

  @override
  String get withdrawStep2Desc =>
      'Our team reviews your documents — usually within minutes.';

  @override
  String get withdrawStep3Title => 'Withdraw Funds';

  @override
  String get withdrawStep3Desc =>
      'Once verified, you can withdraw from your selected aids.';

  @override
  String get continueVerification => 'Continue Verification';

  @override
  String get underReview => 'Under Review';

  @override
  String get retryVerification => 'Retry Verification';

  @override
  String get withdrawReady => 'Ready to Withdraw';

  @override
  String get withdrawalQuota => 'Withdrawal Quota';

  @override
  String get withdrawalDetails => 'Your Selected Aids';

  @override
  String get withdrawalsThisYear => 'Withdrawals this year';

  @override
  String get noWithdrawalsLeft => 'No withdrawals left this year';

  @override
  String withdrawalsRemaining(int count) {
    return '$count withdrawals remaining';
  }

  @override
  String get noAidSelectedYet => 'No Aid Selected';

  @override
  String get noAidSelectedDesc =>
      'Select an aid to see your withdrawal details and available amounts.';

  @override
  String get changeAid => 'Change Aid Selection';

  @override
  String get withdrawn => 'Withdrawn';

  @override
  String get expired => 'Expired';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get withdrawnOn => 'Withdrawn on';

  @override
  String get withdrawalWindow => 'Withdrawal Window';

  @override
  String get aidDates => 'Aid Dates';

  @override
  String get viewPacks => 'View Packs';

  @override
  String get loadMore => 'Load More';
}
