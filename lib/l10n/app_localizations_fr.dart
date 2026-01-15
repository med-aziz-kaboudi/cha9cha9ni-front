// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcomeBack => 'Bienvenue à nouveau';

  @override
  String get createNewAccount => 'Créer un nouveau compte';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ? ';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get firstName => 'Prénom *';

  @override
  String get lastName => 'Nom de famille *';

  @override
  String get enterEmail => 'Entrez votre email *';

  @override
  String get phoneNumber => 'Numéro de téléphone *';

  @override
  String get enterPassword => 'Entrez votre mot de passe *';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get orSignInWith => 'ou se connecter avec';

  @override
  String get orSignUpWith => 'ou s\'inscrire avec';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get signUpWithGoogle => 'S\'inscrire avec Google';

  @override
  String get passwordRequirement1 => 'Doit contenir au moins 8 caractères';

  @override
  String get passwordRequirement2 => 'Contient un chiffre';

  @override
  String get passwordRequirement3 => 'Contient une lettre majuscule';

  @override
  String get passwordRequirement4 => 'Contient un caractère spécial';

  @override
  String termsAgreement(String action) {
    return 'En cliquant sur \"$action\", vous acceptez les ';
  }

  @override
  String get termOfUse => 'Conditions d\'utilisation ';

  @override
  String get and => 'et la ';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get skip => 'Passer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get onboarding1Title =>
      'L\'épargne Fonctionne Mieux\\nQuand Nous le Faisons\\nEnsemble';

  @override
  String get onboarding1Description =>
      'Réunissez votre famille dans un espace partagé et développez votre épargne étape par étape.';

  @override
  String get onboarding2Title =>
      'Économisez\\nPour les Moments\\nQui Vous Tiennent à Cœur';

  @override
  String get onboarding2Description =>
      'Une planification réfléchie pour des moments significatifs, apportant paix et joie à votre famille.';

  @override
  String get otpVerification => 'Vérification OTP';

  @override
  String get verifyEmailSubtitle => 'Nous devons vérifier votre email';

  @override
  String get verifyEmailDescription =>
      'Pour vérifier votre compte, entrez le code OTP à 6 chiffres que nous avons envoyé à votre email.';

  @override
  String get verify => 'Vérifier';

  @override
  String get resendOTP => 'Renvoyer le code';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendOTPIn(String seconds) {
    return 'Renvoyer le code dans ${seconds}s';
  }

  @override
  String get codeExpiresInfo => 'Le code expire dans 15 minutes';

  @override
  String get enterAllDigits => 'Veuillez entrer les 6 chiffres';

  @override
  String get emailVerifiedSuccess => '✅ Email vérifié avec succès!';

  @override
  String verificationFailed(String error) {
    return 'Échec de la vérification: $error';
  }

  @override
  String get verificationSuccess => 'Vérification Réussie!';

  @override
  String get verificationSuccessSubtitle =>
      'Votre email a été vérifié avec succès. Vous pouvez maintenant accéder à toutes les fonctionnalités.';

  @override
  String get okay => 'D\'accord';

  @override
  String pleaseWaitSeconds(String seconds) {
    return 'Veuillez attendre $seconds secondes avant de demander un nouveau code';
  }

  @override
  String get emailAlreadyVerified => 'Email déjà vérifié';

  @override
  String get userNotFound => 'Utilisateur non trouvé';

  @override
  String get invalidVerificationCode => 'Code de vérification invalide';

  @override
  String get verificationCodeExpired =>
      'Code de vérification expiré. Veuillez en demander un nouveau.';

  @override
  String get noVerificationCode =>
      'Aucun code de vérification trouvé. Veuillez en demander un nouveau.';

  @override
  String get registrationSuccessful =>
      'Inscription réussie ! Veuillez vous connecter pour vérifier votre email.';

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
