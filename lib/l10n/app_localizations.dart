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

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong password!'**
  String get passwordStrong;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password requirements'**
  String get passwordRequirements;

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
  /// **'Enter Redemption Code'**
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

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

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
  /// **'Your Current Pack'**
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

  /// No description provided for @leaveFamily.
  ///
  /// In en, this message translates to:
  /// **'Leave Family'**
  String get leaveFamily;

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

  /// No description provided for @topUpCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get topUpCreditCard;

  /// No description provided for @topUpCreditCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay securely with your credit or debit card'**
  String get topUpCreditCardDesc;

  /// No description provided for @topUpPayWithCard.
  ///
  /// In en, this message translates to:
  /// **'Pay with Card'**
  String get topUpPayWithCard;

  /// No description provided for @topUpScratchCard.
  ///
  /// In en, this message translates to:
  /// **'Scratch Card'**
  String get topUpScratchCard;

  /// No description provided for @topUpScratchCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Redeem your scratch card code to add funds'**
  String get topUpScratchCardDesc;

  /// No description provided for @topUpRedeemCard.
  ///
  /// In en, this message translates to:
  /// **'Redeem Card'**
  String get topUpRedeemCard;

  /// No description provided for @topUpCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get topUpCurrentBalance;

  /// No description provided for @topUpFeeNotice.
  ///
  /// In en, this message translates to:
  /// **'Service fees of 5% apply on credit card purchases'**
  String get topUpFeeNotice;

  /// No description provided for @topUpChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose Payment Method'**
  String get topUpChooseMethod;

  /// No description provided for @topUpEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Scratch Card Code'**
  String get topUpEnterCode;

  /// No description provided for @topUpEnterCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Scratch the back of your card to reveal the code and enter it below'**
  String get topUpEnterCodeDesc;

  /// No description provided for @topUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Top Up Successful!'**
  String get topUpSuccess;

  /// No description provided for @topUpPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'points earned'**
  String get topUpPointsEarned;

  /// No description provided for @topUpNewBalance.
  ///
  /// In en, this message translates to:
  /// **'New balance'**
  String get topUpNewBalance;

  /// No description provided for @topUpScanQR.
  ///
  /// In en, this message translates to:
  /// **'Or scan QR code'**
  String get topUpScanQR;

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
  /// **'View all'**
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

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhoto;

  /// No description provided for @tapOptionToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap an option below to update your photo'**
  String get tapOptionToChange;

  /// No description provided for @addPhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a photo to personalize your profile'**
  String get addPhotoDescription;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a new photo now'**
  String get useCamera;

  /// No description provided for @browsePhotos.
  ///
  /// In en, this message translates to:
  /// **'Select from your photo library'**
  String get browsePhotos;

  /// No description provided for @deleteCurrentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove your current profile photo'**
  String get deleteCurrentPhoto;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdated;

  /// No description provided for @cannotRemoveProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'To remove your profile picture, please contact support'**
  String get cannotRemoveProfilePicture;

  /// No description provided for @photoPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access permission denied. Please enable it in Settings.'**
  String get photoPermissionDenied;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image. Please try again.'**
  String get uploadFailed;

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

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @shareInviteCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your family member to add them'**
  String get shareInviteCodeDesc;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @noMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get noMembersYet;

  /// No description provided for @tapAddMemberToInvite.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Member\" to invite your family'**
  String get tapAddMemberToInvite;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from the family?'**
  String removeMemberConfirm(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @confirmRemoval.
  ///
  /// In en, this message translates to:
  /// **'Confirm Removal'**
  String get confirmRemoval;

  /// No description provided for @enterCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your email'**
  String get enterCodeSentToEmail;

  /// No description provided for @enterValidCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit code'**
  String get enterValidCode;

  /// No description provided for @removalInitiated.
  ///
  /// In en, this message translates to:
  /// **'Removal request sent to {name}'**
  String removalInitiated(String name);

  /// No description provided for @acceptRemoval.
  ///
  /// In en, this message translates to:
  /// **'Accept Removal'**
  String get acceptRemoval;

  /// No description provided for @acceptRemovalConfirm.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to remove you from the family. Do you accept?'**
  String acceptRemovalConfirm(String name);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @confirmLeave.
  ///
  /// In en, this message translates to:
  /// **'Confirm Leave'**
  String get confirmLeave;

  /// No description provided for @removedFromFamily.
  ///
  /// In en, this message translates to:
  /// **'Removed from Family'**
  String get removedFromFamily;

  /// No description provided for @removedFromFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'You have been successfully removed from the family. You can now join or create a new family.'**
  String get removedFromFamilyDesc;

  /// No description provided for @removalRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Removal Request'**
  String get removalRequestTitle;

  /// No description provided for @removalRequestDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to remove you from the family.'**
  String removalRequestDesc(String name);

  /// No description provided for @viewRequest.
  ///
  /// In en, this message translates to:
  /// **'View Request'**
  String get viewRequest;

  /// No description provided for @verificationCodeWillBeSent.
  ///
  /// In en, this message translates to:
  /// **'A verification code will be sent to your email'**
  String get verificationCodeWillBeSent;

  /// No description provided for @pendingRemovalRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Removal Requests'**
  String get pendingRemovalRequests;

  /// No description provided for @cancelRemovalRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRemovalRequest;

  /// No description provided for @cancelRemovalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the removal request for {name}?'**
  String cancelRemovalConfirm(String name);

  /// No description provided for @removalCancelled.
  ///
  /// In en, this message translates to:
  /// **'Removal request cancelled'**
  String get removalCancelled;

  /// No description provided for @waitingForMemberConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for member confirmation'**
  String get waitingForMemberConfirmation;

  /// No description provided for @pendingRemoval.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingRemoval;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get choosePreferredLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLanguage;

  /// No description provided for @loginSecurity.
  ///
  /// In en, this message translates to:
  /// **'Login & Security'**
  String get loginSecurity;

  /// No description provided for @securityDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security to protect your account and family data.'**
  String get securityDescription;

  /// No description provided for @passkey.
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get passkey;

  /// No description provided for @sixDigitPasskey.
  ///
  /// In en, this message translates to:
  /// **'6-Digit Passkey'**
  String get sixDigitPasskey;

  /// No description provided for @passkeyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get passkeyEnabled;

  /// No description provided for @passkeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get passkeyNotSet;

  /// No description provided for @passkeyEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected with a 6-digit passkey.'**
  String get passkeyEnabledDescription;

  /// No description provided for @passkeyDescription.
  ///
  /// In en, this message translates to:
  /// **'Save this device for passwordless login. Like PayPal and Wise, you\'ll be able to log in instantly without entering your password.'**
  String get passkeyDescription;

  /// No description provided for @setupPasskey.
  ///
  /// In en, this message translates to:
  /// **'Set Up Passkey'**
  String get setupPasskey;

  /// No description provided for @changePasskey.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changePasskey;

  /// No description provided for @removePasskey.
  ///
  /// In en, this message translates to:
  /// **'Remove Passkey'**
  String get removePasskey;

  /// No description provided for @removePasskeyConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will also disable biometric authentication. You will need to set up a new passkey to re-enable security features.'**
  String get removePasskeyConfirm;

  /// No description provided for @verifyPasskey.
  ///
  /// In en, this message translates to:
  /// **'Verify Passkey'**
  String get verifyPasskey;

  /// No description provided for @enterPasskeyToRemove.
  ///
  /// In en, this message translates to:
  /// **'Enter your passkey to confirm removal'**
  String get enterPasskeyToRemove;

  /// No description provided for @currentPasskey.
  ///
  /// In en, this message translates to:
  /// **'Current Passkey'**
  String get currentPasskey;

  /// No description provided for @enterCurrentPasskey.
  ///
  /// In en, this message translates to:
  /// **'Enter your current passkey'**
  String get enterCurrentPasskey;

  /// No description provided for @newPasskey.
  ///
  /// In en, this message translates to:
  /// **'New Passkey'**
  String get newPasskey;

  /// No description provided for @enterNewPasskey.
  ///
  /// In en, this message translates to:
  /// **'Enter your new 6-digit passkey'**
  String get enterNewPasskey;

  /// No description provided for @confirmPasskey.
  ///
  /// In en, this message translates to:
  /// **'Confirm passkey'**
  String get confirmPasskey;

  /// No description provided for @passkeyMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'Passkey must be 6 digits'**
  String get passkeyMustBe6Digits;

  /// No description provided for @passkeysDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passkeys do not match'**
  String get passkeysDoNotMatch;

  /// No description provided for @passkeySetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Passkey set up successfully'**
  String get passkeySetupSuccess;

  /// No description provided for @passkeyChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Passkey changed successfully'**
  String get passkeyChangedSuccess;

  /// No description provided for @passkeyRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Security settings removed'**
  String get passkeyRemovedSuccess;

  /// No description provided for @faceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get faceId;

  /// No description provided for @fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprint;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get biometricDisabled;

  /// No description provided for @biometricDescription.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics for quick and secure access. Falls back to passkey if biometric fails.'**
  String get biometricDescription;

  /// No description provided for @biometricsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device'**
  String get biometricsNotAvailable;

  /// No description provided for @confirmBiometric.
  ///
  /// In en, this message translates to:
  /// **'Confirm biometric to enable'**
  String get confirmBiometric;

  /// No description provided for @biometricAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get biometricAuthFailed;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @securityStep1.
  ///
  /// In en, this message translates to:
  /// **'When you open the app, you\'ll be asked to verify your identity.'**
  String get securityStep1;

  /// No description provided for @securityStep2.
  ///
  /// In en, this message translates to:
  /// **'First, biometric verification (Face ID / Fingerprint) is attempted if enabled.'**
  String get securityStep2;

  /// No description provided for @securityStep3.
  ///
  /// In en, this message translates to:
  /// **'If biometric fails or is disabled, enter your 6-digit passkey.'**
  String get securityStep3;

  /// No description provided for @securityStep4.
  ///
  /// In en, this message translates to:
  /// **'After 3 failed attempts, your account will be temporarily locked for your protection.'**
  String get securityStep4;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unlockApp.
  ///
  /// In en, this message translates to:
  /// **'Unlock App'**
  String get unlockApp;

  /// No description provided for @enterPasskeyToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter your passkey to unlock'**
  String get enterPasskeyToUnlock;

  /// No description provided for @attemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts remaining'**
  String attemptsRemaining(int count);

  /// No description provided for @accountLocked.
  ///
  /// In en, this message translates to:
  /// **'Account Locked'**
  String get accountLocked;

  /// No description provided for @accountLockedFor.
  ///
  /// In en, this message translates to:
  /// **'Account locked for {duration}'**
  String accountLockedFor(String duration);

  /// No description provided for @accountPermanentlyLocked.
  ///
  /// In en, this message translates to:
  /// **'Account permanently locked. Please contact support.'**
  String get accountPermanentlyLocked;

  /// No description provided for @tryAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Try again in {time}'**
  String tryAgainIn(String time);

  /// No description provided for @useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use {type}'**
  String useBiometric(String type);

  /// No description provided for @usePasskeyInstead.
  ///
  /// In en, this message translates to:
  /// **'Use passkey instead'**
  String get usePasskeyInstead;

  /// No description provided for @usePinInstead.
  ///
  /// In en, this message translates to:
  /// **'Use PIN instead'**
  String get usePinInstead;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pinCode;

  /// No description provided for @sixDigitPin.
  ///
  /// In en, this message translates to:
  /// **'6-Digit PIN'**
  String get sixDigitPin;

  /// No description provided for @setupPinCode.
  ///
  /// In en, this message translates to:
  /// **'Set Up PIN Code'**
  String get setupPinCode;

  /// No description provided for @setupPin.
  ///
  /// In en, this message translates to:
  /// **'Set Up PIN'**
  String get setupPin;

  /// No description provided for @enterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter a 6-digit PIN to secure your account'**
  String get enterNewPin;

  /// No description provided for @pinSetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN Code set up successfully'**
  String get pinSetupSuccess;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get enterCurrentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changePin;

  /// No description provided for @pinChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully'**
  String get pinChangedSuccess;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN Code'**
  String get removePin;

  /// No description provided for @removePinConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove your PIN code. You can set up a new one anytime.'**
  String get removePinConfirm;

  /// No description provided for @verifyPin.
  ///
  /// In en, this message translates to:
  /// **'Verify PIN'**
  String get verifyPin;

  /// No description provided for @enterPinToRemove.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to confirm removal'**
  String get enterPinToRemove;

  /// No description provided for @pinRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN Code removed'**
  String get pinRemovedSuccess;

  /// No description provided for @pinMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 6 digits'**
  String get pinMustBe6Digits;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @pinEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get pinEnabled;

  /// No description provided for @pinNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get pinNotSet;

  /// No description provided for @pinEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected with a 6-digit PIN.'**
  String get pinEnabledDescription;

  /// No description provided for @pinDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up a 6-digit PIN as a backup method to unlock the app.'**
  String get pinDescription;

  /// No description provided for @enterPinToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to unlock'**
  String get enterPinToUnlock;

  /// No description provided for @devicePasskey.
  ///
  /// In en, this message translates to:
  /// **'Device Passkey'**
  String get devicePasskey;

  /// No description provided for @passkeyShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Passwordless device login'**
  String get passkeyShortDesc;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @authenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Authenticator App'**
  String get authenticatorApp;

  /// No description provided for @twoFADescription.
  ///
  /// In en, this message translates to:
  /// **'Use an authenticator app like Google Authenticator or Authy for additional security when logging in.'**
  String get twoFADescription;

  /// No description provided for @twoFAShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Google Authenticator, Authy'**
  String get twoFAShortDesc;

  /// No description provided for @setup2FA.
  ///
  /// In en, this message translates to:
  /// **'Set Up 2FA'**
  String get setup2FA;

  /// No description provided for @pinRequiredForFaceId.
  ///
  /// In en, this message translates to:
  /// **'Please set up PIN code first'**
  String get pinRequiredForFaceId;

  /// No description provided for @requiresPinFirst.
  ///
  /// In en, this message translates to:
  /// **'Requires PIN code'**
  String get requiresPinFirst;

  /// No description provided for @pinFirst.
  ///
  /// In en, this message translates to:
  /// **'PIN first'**
  String get pinFirst;

  /// No description provided for @securityInfoShort.
  ///
  /// In en, this message translates to:
  /// **'Set up PIN code first, then enable Face ID for quick unlock. PIN is your backup if Face ID fails.'**
  String get securityInfoShort;

  /// No description provided for @failedToSetupPin.
  ///
  /// In en, this message translates to:
  /// **'Failed to set up PIN Code'**
  String get failedToSetupPin;

  /// No description provided for @failedToChangePin.
  ///
  /// In en, this message translates to:
  /// **'Failed to change PIN'**
  String get failedToChangePin;

  /// No description provided for @failedToRemovePin.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove PIN'**
  String get failedToRemovePin;

  /// No description provided for @failedToUpdateBiometric.
  ///
  /// In en, this message translates to:
  /// **'Failed to update biometric settings'**
  String get failedToUpdateBiometric;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @codeExpiresAfterUse.
  ///
  /// In en, this message translates to:
  /// **'Code expires after first use'**
  String get codeExpiresAfterUse;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get signInFailed;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign out failed'**
  String get signOutFailed;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed'**
  String get googleSignInFailed;

  /// No description provided for @googleSignUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign up failed'**
  String get googleSignUpFailed;

  /// No description provided for @reenterPinToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your PIN to confirm'**
  String get reenterPinToConfirm;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon!'**
  String get featureComingSoon;

  /// No description provided for @useAnotherMethod.
  ///
  /// In en, this message translates to:
  /// **'Use another method'**
  String get useAnotherMethod;

  /// No description provided for @unlockOptions.
  ///
  /// In en, this message translates to:
  /// **'Unlock Options'**
  String get unlockOptions;

  /// No description provided for @chooseUnlockMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how to unlock'**
  String get chooseUnlockMethod;

  /// No description provided for @tryFaceIdAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Face ID again'**
  String get tryFaceIdAgain;

  /// No description provided for @usePasskey.
  ///
  /// In en, this message translates to:
  /// **'Use Passkey'**
  String get usePasskey;

  /// No description provided for @use2FACode.
  ///
  /// In en, this message translates to:
  /// **'Use 2FA Code'**
  String get use2FACode;

  /// No description provided for @enter2FACode.
  ///
  /// In en, this message translates to:
  /// **'Enter 2FA Code'**
  String get enter2FACode;

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code from your app'**
  String get enter6DigitCode;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCode;

  /// No description provided for @twoFAEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get twoFAEnabled;

  /// No description provided for @twoFADisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA disabled'**
  String get twoFADisabled;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @disable2FA.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get disable2FA;

  /// No description provided for @pinRequiredFor2FA.
  ///
  /// In en, this message translates to:
  /// **'Please set up PIN code first'**
  String get pinRequiredFor2FA;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @enterCodeToDisable2FA.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your authenticator app to confirm'**
  String get enterCodeToDisable2FA;

  /// No description provided for @twoFactorEnabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication enabled!'**
  String get twoFactorEnabled;

  /// No description provided for @secretCopied.
  ///
  /// In en, this message translates to:
  /// **'Secret key copied to clipboard'**
  String get secretCopied;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code'**
  String get scanQrCode;

  /// No description provided for @useAuthenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Open your authenticator app and scan this QR code to add your account'**
  String get useAuthenticatorApp;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orText;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter this key manually'**
  String get enterManually;

  /// No description provided for @copySecretKey.
  ///
  /// In en, this message translates to:
  /// **'Copy secret key'**
  String get copySecretKey;

  /// No description provided for @authenticatorAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'The account name in your authenticator app will be your email address'**
  String get authenticatorAccountInfo;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @enterCodeFromAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app to complete setup'**
  String get enterCodeFromAuthenticator;

  /// No description provided for @codeRefreshesEvery30Seconds.
  ///
  /// In en, this message translates to:
  /// **'Codes refresh every 30 seconds. Make sure to enter the current code.'**
  String get codeRefreshesEvery30Seconds;

  /// No description provided for @activateTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Activate 2FA'**
  String get activateTwoFactor;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again. You need to be connected to use this app.'**
  String get offlineMessage;

  /// No description provided for @connectionTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Try enabling Wi-Fi or mobile data'**
  String get connectionTip;

  /// No description provided for @closeApp.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get closeApp;

  /// No description provided for @retryHint.
  ///
  /// In en, this message translates to:
  /// **'App will automatically reconnect when online'**
  String get retryHint;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordDesc;

  /// No description provided for @changePasswordDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one'**
  String get changePasswordDialogDesc;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @passwordDoesNotMeetRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet requirements'**
  String get passwordDoesNotMeetRequirements;

  /// No description provided for @newPasswordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get newPasswordMustBeDifferent;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @failedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePassword;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get createPassword;

  /// No description provided for @createPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a password for your account'**
  String get createPasswordDesc;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password created successfully'**
  String get passwordCreatedSuccess;

  /// No description provided for @failedToCreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to create password'**
  String get failedToCreatePassword;

  /// No description provided for @alternativeUnlock.
  ///
  /// In en, this message translates to:
  /// **'Alternative Unlock'**
  String get alternativeUnlock;

  /// No description provided for @chooseSecureMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose a secure method to unlock'**
  String get chooseSecureMethod;

  /// No description provided for @authenticatorCode.
  ///
  /// In en, this message translates to:
  /// **'Authenticator Code'**
  String get authenticatorCode;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see important updates here'**
  String get noNotificationsDesc;

  /// No description provided for @allNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsRead;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @setupSecurity.
  ///
  /// In en, this message translates to:
  /// **'Setup Security'**
  String get setupSecurity;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @notificationWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Cha9cha9ni'**
  String get notificationWelcomeTitle;

  /// No description provided for @notificationWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re excited to have you join our community! If you need any help, don\'t hesitate to contact our support team at support@cha9cha9ni.tn or use the Help option in the menu.'**
  String get notificationWelcomeMessage;

  /// No description provided for @notificationProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get notificationProfileTitle;

  /// No description provided for @notificationProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'To make withdrawals and access all our features, please complete your personal information in your profile settings. This helps us verify your identity and keep your account secure.'**
  String get notificationProfileMessage;

  /// No description provided for @notificationSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Account'**
  String get notificationSecurityTitle;

  /// No description provided for @notificationSecurityMessage.
  ///
  /// In en, this message translates to:
  /// **'Protect your account by enabling two-factor authentication (2FA) and setting up a PIN code. This will help safeguard your data and transactions from unauthorized access.'**
  String get notificationSecurityMessage;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @noRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get noRecentActivities;

  /// No description provided for @wantsToRemoveYou.
  ///
  /// In en, this message translates to:
  /// **'Wants to remove'**
  String get wantsToRemoveYou;

  /// No description provided for @ownerRequestedRemoval.
  ///
  /// In en, this message translates to:
  /// **'{ownerName} has requested to remove you from the family'**
  String ownerRequestedRemoval(String ownerName);

  /// No description provided for @respond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get respond;

  /// No description provided for @signingYouIn.
  ///
  /// In en, this message translates to:
  /// **'Signing you in...'**
  String get signingYouIn;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minAgo(int count);

  /// No description provided for @minsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} mins ago'**
  String minsAgo(int count);

  /// No description provided for @hourAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hour ago'**
  String hourAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @dayAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} day ago'**
  String dayAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @monthAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} month ago'**
  String monthAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @scanCode.
  ///
  /// In en, this message translates to:
  /// **'Redeem Gift Card'**
  String get scanCode;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Required'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'We need camera access to scan gift card codes and QR codes.'**
  String get cameraPermissionDescription;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @pointCameraAtCode.
  ///
  /// In en, this message translates to:
  /// **'Point camera at gift card code'**
  String get pointCameraAtCode;

  /// No description provided for @enterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Code Manually'**
  String get enterCodeManually;

  /// No description provided for @scanInstead.
  ///
  /// In en, this message translates to:
  /// **'Scan Instead'**
  String get scanInstead;

  /// No description provided for @enterCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the gift card code to add balance to your account'**
  String get enterCodeDescription;

  /// No description provided for @invalidCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid redemption code'**
  String get invalidCodeFormat;

  /// No description provided for @codeScanned.
  ///
  /// In en, this message translates to:
  /// **'Code Scanned!'**
  String get codeScanned;

  /// No description provided for @joinFamily.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get joinFamily;

  /// No description provided for @rewardsPoints.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get rewardsPoints;

  /// No description provided for @rewardsStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get rewardsStreak;

  /// No description provided for @rewardsAds.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get rewardsAds;

  /// No description provided for @rewardsDailyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get rewardsDailyCheckIn;

  /// No description provided for @rewardsDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak!'**
  String rewardsDayStreak(int count);

  /// No description provided for @rewardsClaimPoints.
  ///
  /// In en, this message translates to:
  /// **'Claim +{points} pts'**
  String rewardsClaimPoints(int points);

  /// No description provided for @rewardsClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get rewardsClaimed;

  /// No description provided for @rewardsNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next in'**
  String get rewardsNextIn;

  /// No description provided for @rewardsWatchAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Watch & Earn'**
  String get rewardsWatchAndEarn;

  /// No description provided for @rewardsWatchAdToEarn.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to earn +{points} pts'**
  String rewardsWatchAdToEarn(int points);

  /// No description provided for @rewardsAllAdsWatched.
  ///
  /// In en, this message translates to:
  /// **'All ads watched today!'**
  String get rewardsAllAdsWatched;

  /// No description provided for @rewardsRedeemRewards.
  ///
  /// In en, this message translates to:
  /// **'Redeem Rewards'**
  String get rewardsRedeemRewards;

  /// No description provided for @rewardsConvertPoints.
  ///
  /// In en, this message translates to:
  /// **'Convert points to TND'**
  String get rewardsConvertPoints;

  /// No description provided for @rewardsRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get rewardsRedeem;

  /// No description provided for @rewardsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get rewardsComingSoon;

  /// No description provided for @rewardsRedeemingFor.
  ///
  /// In en, this message translates to:
  /// **'Redeeming {name} for {points} points will be available soon!'**
  String rewardsRedeemingFor(String name, String points);

  /// No description provided for @rewardsGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get rewardsGotIt;

  /// No description provided for @rewardsSimulatedAd.
  ///
  /// In en, this message translates to:
  /// **'Simulated Ad'**
  String get rewardsSimulatedAd;

  /// No description provided for @rewardsSimulatedAdDesc.
  ///
  /// In en, this message translates to:
  /// **'In production, a real rewarded ad would play here.'**
  String get rewardsSimulatedAdDesc;

  /// No description provided for @rewardsSkipAd.
  ///
  /// In en, this message translates to:
  /// **'Skip Ad'**
  String get rewardsSkipAd;

  /// No description provided for @rewardsWatchComplete.
  ///
  /// In en, this message translates to:
  /// **'Watch Complete'**
  String get rewardsWatchComplete;

  /// No description provided for @rewardsPointsEarned.
  ///
  /// In en, this message translates to:
  /// **'Points earned!'**
  String get rewardsPointsEarned;

  /// No description provided for @rewardsAdReward.
  ///
  /// In en, this message translates to:
  /// **'Ad Reward'**
  String get rewardsAdReward;

  /// No description provided for @rewardsDailyReward.
  ///
  /// In en, this message translates to:
  /// **'Daily Reward'**
  String get rewardsDailyReward;

  /// No description provided for @rewardsLoadingAd.
  ///
  /// In en, this message translates to:
  /// **'Loading ad...'**
  String get rewardsLoadingAd;

  /// No description provided for @rewardsCheckInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check-in successful!'**
  String get rewardsCheckInSuccess;

  /// No description provided for @rewardsCheckInFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-in failed. Please try again.'**
  String get rewardsCheckInFailed;

  /// No description provided for @rewardsClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to claim reward. Please try again.'**
  String get rewardsClaimFailed;

  /// No description provided for @rewardsAdFailed.
  ///
  /// In en, this message translates to:
  /// **'Ad failed to show. Please try again.'**
  String get rewardsAdFailed;

  /// No description provided for @allActivities.
  ///
  /// In en, this message translates to:
  /// **'All Activities'**
  String get allActivities;

  /// No description provided for @activitiesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Family activities will appear here when members earn points'**
  String get activitiesWillAppearHere;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @activityWatchedAd.
  ///
  /// In en, this message translates to:
  /// **'{name} watched an ad'**
  String activityWatchedAd(String name);

  /// No description provided for @activityDailyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'{name} claimed daily check-in'**
  String activityDailyCheckIn(String name);

  /// No description provided for @activityTopUp.
  ///
  /// In en, this message translates to:
  /// **'{name} topped up'**
  String activityTopUp(String name);

  /// No description provided for @activityReferral.
  ///
  /// In en, this message translates to:
  /// **'{name} referral bonus'**
  String activityReferral(String name);

  /// No description provided for @activityEarnedPoints.
  ///
  /// In en, this message translates to:
  /// **'{name} earned points'**
  String activityEarnedPoints(String name);

  /// No description provided for @filterActivities.
  ///
  /// In en, this message translates to:
  /// **'Filter Activities'**
  String get filterActivities;

  /// No description provided for @filterByTime.
  ///
  /// In en, this message translates to:
  /// **'By Time Period'**
  String get filterByTime;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'By Activity Type'**
  String get filterByType;

  /// No description provided for @filterByMember.
  ///
  /// In en, this message translates to:
  /// **'Filter by Member'**
  String get filterByMember;

  /// No description provided for @showOnlyMyActivities.
  ///
  /// In en, this message translates to:
  /// **'Show only my activities'**
  String get showOnlyMyActivities;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterLast10Days.
  ///
  /// In en, this message translates to:
  /// **'Last 10 days'**
  String get filterLast10Days;

  /// No description provided for @filterLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get filterLast7Days;

  /// No description provided for @filterLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get filterLast30Days;

  /// No description provided for @filterLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get filterLast3Months;

  /// No description provided for @filterAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get filterAllTypes;

  /// No description provided for @filterAds.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get filterAds;

  /// No description provided for @filterCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get filterCheckIn;

  /// No description provided for @filterTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get filterTopUp;

  /// No description provided for @filterReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get filterReferral;

  /// No description provided for @filterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterOther;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @noActivitiesForFilter.
  ///
  /// In en, this message translates to:
  /// **'No activities match your filters'**
  String get noActivitiesForFilter;

  /// No description provided for @usageAndLimits.
  ///
  /// In en, this message translates to:
  /// **'Usage and Limits'**
  String get usageAndLimits;

  /// No description provided for @ownerPlusMembers.
  ///
  /// In en, this message translates to:
  /// **'Owner + {count} members'**
  String ownerPlusMembers(int count);

  /// No description provided for @withdrawAccess.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Access'**
  String get withdrawAccess;

  /// No description provided for @ownerOnlyCanWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Owner only can withdraw'**
  String get ownerOnlyCanWithdraw;

  /// No description provided for @youAreOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the family owner'**
  String get youAreOwner;

  /// No description provided for @onlyOwnerCanWithdrawDescription.
  ///
  /// In en, this message translates to:
  /// **'Only the family owner can withdraw funds'**
  String get onlyOwnerCanWithdrawDescription;

  /// No description provided for @kycVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get kycVerified;

  /// No description provided for @kycRequired.
  ///
  /// In en, this message translates to:
  /// **'KYC verification required to withdraw'**
  String get kycRequired;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get verifyIdentity;

  /// No description provided for @selectedAid.
  ///
  /// In en, this message translates to:
  /// **'Selected Aid'**
  String get selectedAid;

  /// No description provided for @selectAnAid.
  ///
  /// In en, this message translates to:
  /// **'Tap to select an aid'**
  String get selectAnAid;

  /// No description provided for @maxDT.
  ///
  /// In en, this message translates to:
  /// **'Max {amount} DT'**
  String maxDT(int amount);

  /// No description provided for @adsToday.
  ///
  /// In en, this message translates to:
  /// **'Ads Today'**
  String get adsToday;

  /// No description provided for @adsPerMember.
  ///
  /// In en, this message translates to:
  /// **'{count} ads / member'**
  String adsPerMember(int count);

  /// No description provided for @watched.
  ///
  /// In en, this message translates to:
  /// **'watched'**
  String get watched;

  /// No description provided for @adsDescription.
  ///
  /// In en, this message translates to:
  /// **'Watch ads to earn points for your family savings'**
  String get adsDescription;

  /// No description provided for @unlockMoreBenefits.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your pack to unlock more benefits, higher withdrawals and more aids'**
  String get unlockMoreBenefits;

  /// No description provided for @changeMyPack.
  ///
  /// In en, this message translates to:
  /// **'Change my pack'**
  String get changeMyPack;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @upToAmount.
  ///
  /// In en, this message translates to:
  /// **'Up to {amount} DT total'**
  String upToAmount(int amount);

  /// No description provided for @withdrawalsPerYear.
  ///
  /// In en, this message translates to:
  /// **'{count} withdrawals / year'**
  String withdrawalsPerYear(int count);

  /// No description provided for @allPacks.
  ///
  /// In en, this message translates to:
  /// **'All Packs'**
  String get allPacks;

  /// No description provided for @choosePack.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Pack'**
  String get choosePack;

  /// No description provided for @choosePackDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the pack that best fits your family\'s needs'**
  String get choosePackDescription;

  /// No description provided for @minimumWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal amount is {amount} DT'**
  String minimumWithdrawal(int amount);

  /// No description provided for @familyMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} family members'**
  String familyMembersCount(int count);

  /// No description provided for @aidsSelectable.
  ///
  /// In en, this message translates to:
  /// **'{count} aids selectable'**
  String aidsSelectable(int count);

  /// No description provided for @currentPack.
  ///
  /// In en, this message translates to:
  /// **'Current Pack'**
  String get currentPack;

  /// No description provided for @selectPack.
  ///
  /// In en, this message translates to:
  /// **'Select Pack'**
  String get selectPack;

  /// No description provided for @upgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {name}'**
  String upgradeTo(String name);

  /// No description provided for @downgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Downgrade to {name}'**
  String downgradeTo(String name);

  /// No description provided for @downgradeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to switch to the Free pack? You may lose access to some features.'**
  String get downgradeConfirmation;

  /// No description provided for @upgradeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {name} for {price} DT/month?'**
  String upgradeConfirmation(String name, int price);

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirmSelection;

  /// No description provided for @subscriptionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Subscription management coming soon!'**
  String get subscriptionComingSoon;

  /// No description provided for @selectAid.
  ///
  /// In en, this message translates to:
  /// **'Select Aid'**
  String get selectAid;

  /// No description provided for @tunisianAids.
  ///
  /// In en, this message translates to:
  /// **'Tunisian Aids'**
  String get tunisianAids;

  /// No description provided for @selectionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} selections available'**
  String selectionsRemaining(int remaining, int total);

  /// No description provided for @aidSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred aid for withdrawal. Each aid has specific withdrawal windows and maximum amounts.'**
  String get aidSelectionDescription;

  /// No description provided for @aidSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'The amount shown is the maximum you can withdraw during this aid\'s window period after selecting it.'**
  String get aidSelectionHint;

  /// No description provided for @packBasedWithdrawalHint.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your pack to unlock higher withdrawal limits and select more aids!'**
  String get packBasedWithdrawalHint;

  /// No description provided for @withdrawalLimit.
  ///
  /// In en, this message translates to:
  /// **'You can withdraw up to'**
  String get withdrawalLimit;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached'**
  String get limitReached;

  /// No description provided for @yourSelectedAids.
  ///
  /// In en, this message translates to:
  /// **'Your Selected Aids'**
  String get yourSelectedAids;

  /// No description provided for @availableAids.
  ///
  /// In en, this message translates to:
  /// **'Available Aids'**
  String get availableAids;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @maxWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Max withdrawal'**
  String get maxWithdrawal;

  /// No description provided for @window.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get window;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @aidAlreadySelected.
  ///
  /// In en, this message translates to:
  /// **'This aid is already selected'**
  String get aidAlreadySelected;

  /// No description provided for @maxAidsReached.
  ///
  /// In en, this message translates to:
  /// **'You can only select {count} aid(s) with your current pack'**
  String maxAidsReached(int count);

  /// No description provided for @selectAidConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Aid Selection'**
  String get selectAidConfirmTitle;

  /// No description provided for @selectAidConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to select {name}?'**
  String selectAidConfirmMessage(String name);

  /// No description provided for @aidSelectionWarning.
  ///
  /// In en, this message translates to:
  /// **'You cannot change your selected aid without contacting support'**
  String get aidSelectionWarning;

  /// No description provided for @aidSelectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} has been selected successfully'**
  String aidSelectedSuccess(String name);

  /// No description provided for @viewOnlyPackInfo.
  ///
  /// In en, this message translates to:
  /// **'Only the family owner can manage pack and aids'**
  String get viewOnlyPackInfo;

  /// No description provided for @noAidSelected.
  ///
  /// In en, this message translates to:
  /// **'No aid selected yet'**
  String get noAidSelected;

  /// No description provided for @daysUntilAid.
  ///
  /// In en, this message translates to:
  /// **'{days} days until {aidName}'**
  String daysUntilAid(int days, String aidName);

  /// No description provided for @aidWindowOpen.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal window is open!'**
  String get aidWindowOpen;

  /// No description provided for @aidWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Window opens in {days} days'**
  String aidWindowClosed(int days);

  /// No description provided for @leaveFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Family'**
  String get leaveFamilyTitle;

  /// No description provided for @leaveFamilyConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this family? Your points will stay with your current family and you will start fresh if you join a new one.'**
  String get leaveFamilyConfirmMessage;

  /// No description provided for @leaveFamilyWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get leaveFamilyWarning;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveFamilyCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code sent to your email'**
  String get leaveFamilyCodeSent;

  /// No description provided for @leaveFamilySuccess.
  ///
  /// In en, this message translates to:
  /// **'You have successfully left the family'**
  String get leaveFamilySuccess;

  /// No description provided for @leaveFamilyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Leave'**
  String get leaveFamilyConfirmTitle;

  /// No description provided for @leaveFamilyCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email to confirm leaving the family'**
  String get leaveFamilyCodePrompt;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in'**
  String get resendCodeIn;

  /// No description provided for @codeSentAgain.
  ///
  /// In en, this message translates to:
  /// **'Code sent again'**
  String get codeSentAgain;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again in {minutes} minutes.'**
  String tooManyAttempts(Object minutes);

  /// No description provided for @tooManyAttemptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Too Many Attempts'**
  String get tooManyAttemptsTitle;

  /// No description provided for @rateLimitedWait.
  ///
  /// In en, this message translates to:
  /// **'Rate limited. Please wait {time}'**
  String rateLimitedWait(String time);

  /// No description provided for @tooManyRefreshes.
  ///
  /// In en, this message translates to:
  /// **'Too many refreshes. Please wait {minutes} minutes.'**
  String tooManyRefreshes(int minutes);

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @statementTitle.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get statementTitle;

  /// No description provided for @statementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a start date to generate your statement and receive it via email'**
  String get statementSubtitle;

  /// No description provided for @statementSelectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select Start Date'**
  String get statementSelectStartDate;

  /// No description provided for @statementDateHint.
  ///
  /// In en, this message translates to:
  /// **'Statement from this date to today'**
  String get statementDateHint;

  /// No description provided for @statementYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statementYear;

  /// No description provided for @statementMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statementMonth;

  /// No description provided for @statementPeriod.
  ///
  /// In en, this message translates to:
  /// **'Statement Period'**
  String get statementPeriod;

  /// No description provided for @statementToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statementToday;

  /// No description provided for @statementSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get statementSelectDate;

  /// No description provided for @statementNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity found for this period. Please select another date.'**
  String get statementNoActivity;

  /// No description provided for @statementLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. Please try again.'**
  String get statementLoadError;

  /// No description provided for @statementGenerateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate statement. Please try again.'**
  String get statementGenerateError;

  /// No description provided for @statementSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get statementSending;

  /// No description provided for @statementSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send to My Email'**
  String get statementSendButton;

  /// No description provided for @statementRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Limit reached! You can only send 2 statements per day.'**
  String get statementRateLimitError;

  /// No description provided for @statementRateLimitNote.
  ///
  /// In en, this message translates to:
  /// **'Limited to 2 sends per day'**
  String get statementRateLimitNote;

  /// No description provided for @statementRemainingEmails.
  ///
  /// In en, this message translates to:
  /// **'{count} send(s) remaining today'**
  String statementRemainingEmails(int count);

  /// No description provided for @statementSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Statement Sent!'**
  String get statementSentTitle;

  /// No description provided for @statementSentDescription.
  ///
  /// In en, this message translates to:
  /// **'Your statement from {startDate} to today has been sent to'**
  String statementSentDescription(String startDate);

  /// No description provided for @statementGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get statementGotIt;
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
