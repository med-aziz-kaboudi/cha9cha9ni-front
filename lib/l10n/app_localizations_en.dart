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
}
