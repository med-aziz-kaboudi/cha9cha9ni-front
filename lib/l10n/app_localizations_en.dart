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
}
