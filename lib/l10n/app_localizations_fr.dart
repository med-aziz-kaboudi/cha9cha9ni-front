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
      'L\'épargne Fonctionne Mieux\nQuand Nous le Faisons\nEnsemble';

  @override
  String get onboarding1Description =>
      'Réunissez votre famille dans un espace partagé et développez votre épargne étape par étape.';

  @override
  String get onboarding2Title =>
      'Économisez\nPour les Moments\nQui Vous Tiennent à Cœur';

  @override
  String get onboarding2Description =>
      'Une planification réfléchie pour des moments significatifs, apportant paix et joie à votre famille.';
}
