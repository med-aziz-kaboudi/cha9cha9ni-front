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
  String get resendOtp => 'Renvoyer le code';

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
  String get resetPassword => 'Réinitialiser le Mot de Passe';

  @override
  String get newPassword => 'Nouveau Mot de Passe';

  @override
  String get enterNewPassword => 'Entrez votre nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le Mot de Passe';

  @override
  String get confirmYourPassword => 'Confirmez votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordResetSuccessfully =>
      'Mot de passe réinitialisé avec succès ! Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.';

  @override
  String get checkYourMailbox => 'Vérifiez Votre Boîte Mail';

  @override
  String weHaveSentResetCodeTo(String email) {
    return 'Nous avons envoyé un code de réinitialisation à 6 chiffres à $email';
  }

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre adresse email';

  @override
  String get invalidEmailFormat => 'Veuillez entrer une adresse email valide';

  @override
  String get pleaseEnterComplete6DigitCode =>
      'Veuillez entrer le code complet à 6 chiffres';

  @override
  String get codeSentSuccessfully =>
      'Code envoyé avec succès ! Veuillez vérifier votre email.';

  @override
  String get anErrorOccurred =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get didntReceiveCode => 'Vous n\'avez pas reçu le code ?';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get enterYourPassword => 'Entrez votre mot de passe';

  @override
  String get joinOrCreateFamily => 'Rejoindre ou Créer une Famille';

  @override
  String get chooseHowToProceed =>
      'Choisissez comment vous souhaitez continuer';

  @override
  String get createAFamily => 'Créer une Famille';

  @override
  String get joinAFamily => 'Rejoindre une Famille';

  @override
  String get enterInviteCode => 'XXXX-XXXX';

  @override
  String get pleaseEnterInviteCode => 'Veuillez entrer le code d\'invitation';

  @override
  String get failedToCreateFamily => 'Échec de la création de la famille';

  @override
  String get failedToJoinFamily => 'Échec de rejoindre la famille';

  @override
  String get joinNow => 'Rejoindre Maintenant';

  @override
  String get cancel => 'Annuler';

  @override
  String get signOut => 'Se Déconnecter';

  @override
  String get familyInviteCode => 'Code d\'Invitation Familiale';

  @override
  String get shareThisCode =>
      'Partagez ce code avec les membres de votre famille pour qu\'ils puissent rejoindre';

  @override
  String get copyCode => 'Copier le Code';

  @override
  String get codeCopied => 'Code d\'invitation copié!';

  @override
  String get gotIt => 'Compris!';

  @override
  String get welcomeFamilyOwner => 'Bienvenue, Propriétaire de la Famille!';

  @override
  String get welcomeFamilyMember => 'Bienvenue, Membre de la Famille!';

  @override
  String get yourFamily => 'Votre Famille';

  @override
  String get owner => 'Propriétaire';

  @override
  String get members => 'Membres';

  @override
  String get noCodeAvailable => 'Aucun code disponible';

  @override
  String get inviteCodeCopiedToClipboard => 'Code d\'invitation copié!';

  @override
  String get shareCodeWithFamilyMembers =>
      'Partagez ce code avec les membres de votre famille.\nIl changera après chaque utilisation.';

  @override
  String get scanButtonTapped => 'Bouton de scan appuyé';

  @override
  String get rewardScreenComingSoon =>
      'Écran de récompenses bientôt disponible';

  @override
  String get home => 'Accueil';

  @override
  String get reward => 'Récompenses';

  @override
  String get myFamily => 'Ma Famille';
}
