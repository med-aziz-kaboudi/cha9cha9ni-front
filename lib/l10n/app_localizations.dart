import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name *'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name *'**
  String get lastName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email *'**
  String get enterEmail;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number *'**
  String get phoneNumber;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password *'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'or sign in with'**
  String get orSignInWith;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'or sign up with'**
  String get orSignUpWith;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @passwordRequirement1.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least 8 characters'**
  String get passwordRequirement1;

  /// No description provided for @passwordRequirement2.
  ///
  /// In en, this message translates to:
  /// **'Contains a number'**
  String get passwordRequirement2;

  /// No description provided for @passwordRequirement3.
  ///
  /// In en, this message translates to:
  /// **'Contains an uppercase letter'**
  String get passwordRequirement3;

  /// No description provided for @passwordRequirement4.
  ///
  /// In en, this message translates to:
  /// **'Contains a special character'**
  String get passwordRequirement4;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By clicking \"{action}\" you agree to Cha9cha9ni '**
  String termsAgreement(String action);

  /// No description provided for @termOfUse.
  ///
  /// In en, this message translates to:
  /// **'Term of Use '**
  String get termOfUse;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Saving Works Better\nWhen We Do It\nTogether'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Description.
  ///
  /// In en, this message translates to:
  /// **'Bring your family into one shared space and grow your savings step by step.'**
  String get onboarding1Description;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Save\nFor the Moments\nYou Care About'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Description.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful planning for meaningful moments, bringing peace and joy to your family.'**
  String get onboarding2Description;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP\nVerification'**
  String get otpVerification;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need to verify your email'**
  String get verifyEmailSubtitle;

  /// No description provided for @verifyEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'To verify your account, enter the 6 digit OTP code that we sent to your email.'**
  String get verifyEmailDescription;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendOTP.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOTP;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendOTPIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String resendOTPIn(String seconds);

  /// No description provided for @codeExpiresInfo.
  ///
  /// In en, this message translates to:
  /// **'The code expires in 15 minutes'**
  String get codeExpiresInfo;

  /// No description provided for @enterAllDigits.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get enterAllDigits;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Email verified successfully!'**
  String get emailVerifiedSuccess;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String verificationFailed(String error);

  /// No description provided for @verificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification Success!'**
  String get verificationSuccess;

  /// No description provided for @verificationSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your email has been verified successfully. You can now access all features.'**
  String get verificationSuccessSubtitle;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @pleaseWaitSeconds.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before requesting a new code'**
  String pleaseWaitSeconds(String seconds);

  /// No description provided for @emailAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Email already verified'**
  String get emailAlreadyVerified;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidVerificationCode;

  /// No description provided for @verificationCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification code expired. Please request a new one.'**
  String get verificationCodeExpired;

  /// No description provided for @noVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'No verification code found. Please request a new one.'**
  String get noVerificationCode;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please sign in to verify your email.'**
  String get registrationSuccessful;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordResetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully! You can now sign in with your new password.'**
  String get passwordResetSuccessfully;

  /// No description provided for @checkYourMailbox.
  ///
  /// In en, this message translates to:
  /// **'Check Your Mailbox'**
  String get checkYourMailbox;

  /// No description provided for @weHaveSentResetCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We have sent a 6-digit reset code to {email}'**
  String weHaveSentResetCodeTo(String email);

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmail;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailFormat;

  /// No description provided for @pleaseEnterComplete6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code'**
  String get pleaseEnterComplete6DigitCode;

  /// No description provided for @codeSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Code sent successfully! Please check your email.'**
  String get codeSentSuccessfully;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get anErrorOccurred;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code?'**
  String get didntReceiveCode;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @joinOrCreateFamily.
  ///
  /// In en, this message translates to:
  /// **'Join or Create a Family'**
  String get joinOrCreateFamily;

  /// No description provided for @chooseHowToProceed.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to proceed'**
  String get chooseHowToProceed;

  /// No description provided for @createAFamily.
  ///
  /// In en, this message translates to:
  /// **'Create a Family'**
  String get createAFamily;

  /// No description provided for @joinAFamily.
  ///
  /// In en, this message translates to:
  /// **'Join a Family'**
  String get joinAFamily;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'XXXX-XXXX'**
  String get enterInviteCode;

  /// No description provided for @pleaseEnterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter an invite code'**
  String get pleaseEnterInviteCode;

  /// No description provided for @failedToCreateFamily.
  ///
  /// In en, this message translates to:
  /// **'Failed to create family'**
  String get failedToCreateFamily;

  /// No description provided for @failedToJoinFamily.
  ///
  /// In en, this message translates to:
  /// **'Failed to join family'**
  String get failedToJoinFamily;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get joinNow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @familyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Family Invite Code'**
  String get familyInviteCode;

  /// No description provided for @shareThisCode.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your family members so they can join your family.'**
  String get shareThisCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard!'**
  String get codeCopied;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @welcomeFamilyOwner.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Family Owner!'**
  String get welcomeFamilyOwner;

  /// No description provided for @welcomeFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Family Member!'**
  String get welcomeFamilyMember;

  /// No description provided for @yourFamily.
  ///
  /// In en, this message translates to:
  /// **'Your Family'**
  String get yourFamily;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @noCodeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No code available'**
  String get noCodeAvailable;

  /// No description provided for @inviteCodeCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard!'**
  String get inviteCodeCopiedToClipboard;

  /// No description provided for @shareCodeWithFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Share this code with family members.\nIt will change after each use.'**
  String get shareCodeWithFamilyMembers;

  /// No description provided for @scanButtonTapped.
  ///
  /// In en, this message translates to:
  /// **'Scan button tapped'**
  String get scanButtonTapped;

  /// No description provided for @rewardScreenComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reward screen coming soon'**
  String get rewardScreenComingSoon;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @myFamily.
  ///
  /// In en, this message translates to:
  /// **'My Family'**
  String get myFamily;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @yourCurrentPack.
  ///
  /// In en, this message translates to:
  /// **'Your current pack'**
  String get yourCurrentPack;

  /// No description provided for @loginAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Log in & security'**
  String get loginAndSecurity;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @legalAgreements.
  ///
  /// In en, this message translates to:
  /// **'Legal Agreements'**
  String get legalAgreements;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @topUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUp;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'withdraw'**
  String get withdraw;

  /// No description provided for @statement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get statement;

  /// No description provided for @nextWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Next Withdrawal'**
  String get nextWithdrawal;

  /// No description provided for @availableInDays.
  ///
  /// In en, this message translates to:
  /// **'Available in {days} days'**
  String availableInDays(int days);

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembers;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage >'**
  String get manage;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent activities :'**
  String get recentActivities;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all  >'**
  String get viewAll;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign In Cancelled'**
  String get googleSignInCancelled;

  /// No description provided for @googleSignInCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'You cancelled the Google sign in. Please try again to continue.'**
  String get googleSignInCancelledMessage;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pts;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpiredTitle;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Another device has logged into your account. You will be signed out for security.'**
  String get sessionExpiredMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @skipTutorial.
  ///
  /// In en, this message translates to:
  /// **'Skip Guide'**
  String get skipTutorial;

  /// No description provided for @nextTutorial.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextTutorial;

  /// No description provided for @doneTutorial.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get doneTutorial;

  /// No description provided for @tutorialSidebarTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get tutorialSidebarTitle;

  /// No description provided for @tutorialSidebarDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap here to open the sidebar menu. Access your profile, settings, and more options.'**
  String get tutorialSidebarDesc;

  /// No description provided for @tutorialTopUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get tutorialTopUpTitle;

  /// No description provided for @tutorialTopUpDesc.
  ///
  /// In en, this message translates to:
  /// **'Add money to your family account. Share funds with your family members easily.'**
  String get tutorialTopUpDesc;

  /// No description provided for @tutorialWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get tutorialWithdrawTitle;

  /// No description provided for @tutorialWithdrawDesc.
  ///
  /// In en, this message translates to:
  /// **'Request to withdraw money from your family savings when you need it.'**
  String get tutorialWithdrawDesc;

  /// No description provided for @tutorialStatementTitle.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get tutorialStatementTitle;

  /// No description provided for @tutorialStatementDesc.
  ///
  /// In en, this message translates to:
  /// **'View all your transactions history. Track your family\'s spending and savings.'**
  String get tutorialStatementDesc;

  /// No description provided for @tutorialPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward Points'**
  String get tutorialPointsTitle;

  /// No description provided for @tutorialPointsDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn points for every activity! Redeem them for exclusive rewards and benefits.'**
  String get tutorialPointsDesc;

  /// No description provided for @tutorialNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tutorialNotificationTitle;

  /// No description provided for @tutorialNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay updated with family activities, transactions, and important alerts.'**
  String get tutorialNotificationDesc;

  /// No description provided for @tutorialQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get tutorialQrCodeTitle;

  /// No description provided for @tutorialQrCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan QR codes to make quick payments or add new family members.'**
  String get tutorialQrCodeDesc;

  /// No description provided for @tutorialRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get tutorialRewardTitle;

  /// No description provided for @tutorialRewardDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore and redeem your earned points for amazing rewards and discounts.'**
  String get tutorialRewardDesc;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @verifyCurrentEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'To change your email, we first need to verify your current email address.'**
  String get verifyCurrentEmailDesc;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @enterCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}'**
  String enterCodeSentTo(String email);

  /// No description provided for @currentEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Current email verified'**
  String get currentEmailVerified;

  /// No description provided for @enterNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your new email address'**
  String get enterNewEmail;

  /// No description provided for @newEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'newemail@example.com'**
  String get newEmailPlaceholder;

  /// No description provided for @confirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Change'**
  String get confirmChange;

  /// No description provided for @emailUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email updated successfully!'**
  String get emailUpdatedSuccessfully;

  /// No description provided for @phoneNumberMustBe8Digits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be exactly 8 digits'**
  String get phoneNumberMustBe8Digits;

  /// No description provided for @phoneNumberAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already in use'**
  String get phoneNumberAlreadyInUse;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
