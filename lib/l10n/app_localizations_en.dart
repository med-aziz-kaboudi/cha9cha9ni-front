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
}
