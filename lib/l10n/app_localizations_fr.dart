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
  String get passwordStrong => 'Mot de passe fort !';

  @override
  String get passwordRequirements => 'Exigences du mot de passe';

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
  String get enterInviteCode => 'Entrer le code de remboursement';

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
  String get you => 'Vous';

  @override
  String get member => 'Membre';

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

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get yourCurrentPack => 'Votre Pack Actuel';

  @override
  String get loginAndSecurity => 'Connexion et sécurité';

  @override
  String get languages => 'Langues';

  @override
  String get notifications => 'Notifications';

  @override
  String get help => 'Aide';

  @override
  String get legalAgreements => 'Accords juridiques';

  @override
  String get leaveFamily => 'Quitter la famille';

  @override
  String get logout => 'Déconnexion';

  @override
  String get balance => 'Solde';

  @override
  String get topUp => 'Recharger';

  @override
  String get topUpCreditCard => 'Carte Bancaire';

  @override
  String get topUpCreditCardDesc => 'Payez en toute sécurité avec votre carte';

  @override
  String get topUpPayWithCard => 'Payer par Carte';

  @override
  String get topUpScratchCard => 'Carte à Gratter';

  @override
  String get topUpScratchCardDesc =>
      'Utilisez le code de votre carte à gratter';

  @override
  String get topUpRedeemCard => 'Utiliser la Carte';

  @override
  String get topUpCurrentBalance => 'Solde Actuel';

  @override
  String get topUpFeeNotice =>
      'Des frais de service de 5% s\'appliquent aux paiements par carte';

  @override
  String get topUpChooseMethod => 'Choisir le Mode de Paiement';

  @override
  String get topUpEnterCode => 'Entrez le Code de la Carte';

  @override
  String get topUpEnterCodeDesc =>
      'Grattez le dos de votre carte pour révéler le code et entrez-le ci-dessous';

  @override
  String get topUpSuccess => 'Recharge Réussie!';

  @override
  String get topUpPointsEarned => 'points gagnés';

  @override
  String get topUpNewBalance => 'Nouveau solde';

  @override
  String get topUpScanQR => 'Ou scanner le code QR';

  @override
  String get withdraw => 'Retirer';

  @override
  String get statement => 'Relevé';

  @override
  String get nextWithdrawal => 'Prochain retrait';

  @override
  String availableInDays(int days) {
    return 'Disponible dans $days jours';
  }

  @override
  String get familyMembers => 'Membres de la Famille';

  @override
  String get manage => 'Gérer >';

  @override
  String get recentActivities => 'Activités récentes :';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get googleSignInCancelled => 'Connexion Annulée';

  @override
  String get googleSignInCancelledMessage =>
      'Vous avez annulé la connexion Google. Veuillez réessayer pour continuer.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get pts => 'pts';

  @override
  String get sessionExpiredTitle => 'Session Expirée';

  @override
  String get sessionExpiredMessage =>
      'Un autre appareil s\'est connecté à votre compte. Vous serez déconnecté pour des raisons de sécurité.';

  @override
  String get ok => 'OK';

  @override
  String get skipTutorial => 'Passer le guide';

  @override
  String get nextTutorial => 'Suivant';

  @override
  String get doneTutorial => 'Compris!';

  @override
  String get tutorialSidebarTitle => 'Menu';

  @override
  String get tutorialSidebarDesc =>
      'Appuyez ici pour ouvrir le menu latéral. Accédez à votre profil, paramètres et plus.';

  @override
  String get tutorialTopUpTitle => 'Recharger';

  @override
  String get tutorialTopUpDesc =>
      'Ajoutez de l\'argent à votre compte familial. Partagez des fonds facilement.';

  @override
  String get tutorialWithdrawTitle => 'Retirer';

  @override
  String get tutorialWithdrawDesc =>
      'Demandez à retirer de l\'argent de vos économies familiales.';

  @override
  String get tutorialStatementTitle => 'Relevé';

  @override
  String get tutorialStatementDesc =>
      'Consultez l\'historique de toutes vos transactions. Suivez les dépenses et économies.';

  @override
  String get tutorialPointsTitle => 'Points de Récompense';

  @override
  String get tutorialPointsDesc =>
      'Gagnez des points pour chaque activité! Échangez-les contre des récompenses.';

  @override
  String get tutorialNotificationTitle => 'Notifications';

  @override
  String get tutorialNotificationDesc =>
      'Restez informé des activités familiales, transactions et alertes importantes.';

  @override
  String get tutorialQrCodeTitle => 'Scanner QR';

  @override
  String get tutorialQrCodeDesc =>
      'Scannez des codes QR pour des paiements rapides ou ajouter des membres.';

  @override
  String get tutorialRewardTitle => 'Récompenses';

  @override
  String get tutorialRewardDesc =>
      'Explorez et échangez vos points gagnés contre des récompenses et réductions.';

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get email => 'Email';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get lastNameLabel => 'Nom de famille';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get firstNameRequired => 'Le prénom est requis';

  @override
  String get lastNameRequired => 'Le nom de famille est requis';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès!';

  @override
  String get fullName => 'Nom complet';

  @override
  String get edit => 'Modifier';

  @override
  String get changeEmail => 'Changer l\'Email';

  @override
  String get verifyCurrentEmailDesc =>
      'Pour changer votre email, nous devons d\'abord vérifier votre adresse email actuelle.';

  @override
  String get sendVerificationCode => 'Envoyer le Code';

  @override
  String enterCodeSentTo(String email) {
    return 'Entrez le code à 6 chiffres envoyé à $email';
  }

  @override
  String get currentEmailVerified => 'Email actuel vérifié';

  @override
  String get enterNewEmail => 'Entrez votre nouvelle adresse email';

  @override
  String get newEmailPlaceholder => 'newemail@example.com';

  @override
  String get confirmChange => 'Confirmer le Changement';

  @override
  String get emailUpdatedSuccessfully => 'Email mis à jour avec succès!';

  @override
  String get phoneNumberMustBe8Digits =>
      'Le numéro de téléphone doit comporter exactement 8 chiffres';

  @override
  String get phoneNumberAlreadyInUse =>
      'Ce numéro de téléphone est déjà utilisé';

  @override
  String get addMember => 'Ajouter un Membre';

  @override
  String get shareInviteCodeDesc =>
      'Partagez ce code avec votre membre de famille pour l\'ajouter';

  @override
  String get copy => 'Copier';

  @override
  String get noMembersYet => 'Pas encore de membres';

  @override
  String get tapAddMemberToInvite =>
      'Appuyez sur \"Ajouter un Membre\" pour inviter votre famille';

  @override
  String get removeMember => 'Supprimer le Membre';

  @override
  String removeMemberConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer $name de la famille ?';
  }

  @override
  String get remove => 'Supprimer';

  @override
  String get confirmRemoval => 'Confirmer la Suppression';

  @override
  String get enterCodeSentToEmail =>
      'Entrez le code de vérification envoyé à votre email';

  @override
  String get enterValidCode => 'Entrez un code à 6 chiffres valide';

  @override
  String removalInitiated(String name) {
    return 'Demande de suppression envoyée à $name';
  }

  @override
  String get acceptRemoval => 'Accepter la Suppression';

  @override
  String acceptRemovalConfirm(String name) {
    return '$name souhaite vous retirer de la famille. Acceptez-vous ?';
  }

  @override
  String get decline => 'Refuser';

  @override
  String get accept => 'Accepter';

  @override
  String get confirmLeave => 'Confirmer le Départ';

  @override
  String get removedFromFamily => 'Retiré de la Famille';

  @override
  String get removedFromFamilyDesc =>
      'Vous avez été retiré de la famille avec succès. Vous pouvez maintenant rejoindre ou créer une nouvelle famille.';

  @override
  String get removalRequestTitle => 'Demande de Suppression';

  @override
  String removalRequestDesc(String name) {
    return '$name souhaite vous retirer de la famille.';
  }

  @override
  String get viewRequest => 'Voir la Demande';

  @override
  String get verificationCodeWillBeSent =>
      'Un code de vérification sera envoyé à votre email';

  @override
  String get pendingRemovalRequests => 'Demandes de Suppression en Attente';

  @override
  String get cancelRemovalRequest => 'Annuler la Demande';

  @override
  String cancelRemovalConfirm(String name) {
    return 'Êtes-vous sûr de vouloir annuler la demande de suppression pour $name ?';
  }

  @override
  String get removalCancelled => 'Demande de suppression annulée';

  @override
  String get waitingForMemberConfirmation =>
      'En attente de la confirmation du membre';

  @override
  String get pendingRemoval => 'En attente';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get choosePreferredLanguage => 'Choisissez votre langue préférée';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageChanged => 'Langue modifiée avec succès';

  @override
  String get currentLanguage => 'Actuel';

  @override
  String get loginSecurity => 'Connexion & Sécurité';

  @override
  String get securityDescription =>
      'Ajoutez une couche de sécurité supplémentaire pour protéger votre compte et les données de votre famille.';

  @override
  String get passkey => 'Code d\'accès';

  @override
  String get sixDigitPasskey => 'Code à 6 chiffres';

  @override
  String get passkeyEnabled => 'Activé';

  @override
  String get passkeyNotSet => 'Non configuré';

  @override
  String get passkeyEnabledDescription =>
      'Votre compte est protégé par un code à 6 chiffres.';

  @override
  String get passkeyDescription =>
      'Enregistrez cet appareil pour une connexion sans mot de passe. Comme PayPal et Wise, vous pourrez vous connecter instantanément.';

  @override
  String get setupPasskey => 'Configurer la clé d\'accès';

  @override
  String get changePasskey => 'Modifier';

  @override
  String get removePasskey => 'Supprimer le code';

  @override
  String get removePasskeyConfirm =>
      'Cela désactivera également l\'authentification biométrique. Vous devrez configurer un nouveau code pour réactiver les fonctionnalités de sécurité.';

  @override
  String get verifyPasskey => 'Vérifier le code';

  @override
  String get enterPasskeyToRemove =>
      'Entrez votre code pour confirmer la suppression';

  @override
  String get currentPasskey => 'Code actuel';

  @override
  String get enterCurrentPasskey => 'Entrez votre code actuel';

  @override
  String get newPasskey => 'Nouveau code';

  @override
  String get enterNewPasskey => 'Entrez votre nouveau code à 6 chiffres';

  @override
  String get confirmPasskey => 'Confirmer le code';

  @override
  String get passkeyMustBe6Digits => 'Le code doit contenir 6 chiffres';

  @override
  String get passkeysDoNotMatch => 'Les codes ne correspondent pas';

  @override
  String get passkeySetupSuccess => 'Code configuré avec succès';

  @override
  String get passkeyChangedSuccess => 'Code modifié avec succès';

  @override
  String get passkeyRemovedSuccess => 'Paramètres de sécurité supprimés';

  @override
  String get faceId => 'Face ID';

  @override
  String get fingerprint => 'Empreinte digitale';

  @override
  String get biometrics => 'Biométrie';

  @override
  String get biometricEnabled => 'Activé';

  @override
  String get biometricDisabled => 'Désactivé';

  @override
  String get biometricDescription =>
      'Utilisez la biométrie pour un accès rapide et sécurisé. Revient au code en cas d\'échec.';

  @override
  String get biometricsNotAvailable =>
      'Biométrie non disponible sur cet appareil';

  @override
  String get confirmBiometric => 'Confirmez la biométrie pour activer';

  @override
  String get biometricAuthFailed => 'Échec de l\'authentification biométrique';

  @override
  String get howItWorks => 'Comment ça marche';

  @override
  String get securityStep1 =>
      'Lorsque vous ouvrez l\'application, vous devrez vérifier votre identité.';

  @override
  String get securityStep2 =>
      'D\'abord, la vérification biométrique (Face ID / Empreinte) est tentée si activée.';

  @override
  String get securityStep3 =>
      'Si la biométrie échoue ou est désactivée, entrez votre code à 6 chiffres.';

  @override
  String get securityStep4 =>
      'Après 3 échecs, votre compte sera temporairement verrouillé pour votre protection.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get unlockApp => 'Déverrouiller l\'application';

  @override
  String get enterPasskeyToUnlock => 'Entrez votre code pour déverrouiller';

  @override
  String attemptsRemaining(int count) {
    return '$count tentatives restantes';
  }

  @override
  String get accountLocked => 'Compte verrouillé';

  @override
  String accountLockedFor(String duration) {
    return 'Compte verrouillé pendant $duration';
  }

  @override
  String get accountPermanentlyLocked =>
      'Compte définitivement verrouillé. Veuillez contacter le support.';

  @override
  String tryAgainIn(String time) {
    return 'Réessayez dans $time';
  }

  @override
  String useBiometric(String type) {
    return 'Utiliser $type';
  }

  @override
  String get usePasskeyInstead => 'Utiliser le code à la place';

  @override
  String get usePinInstead => 'Utiliser le PIN à la place';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get sixDigitPin => 'PIN à 6 chiffres';

  @override
  String get setupPinCode => 'Configurer le code PIN';

  @override
  String get setupPin => 'Configurer PIN';

  @override
  String get enterNewPin =>
      'Entrez un PIN à 6 chiffres pour sécuriser votre compte';

  @override
  String get pinSetupSuccess => 'Code PIN configuré avec succès';

  @override
  String get currentPin => 'PIN actuel';

  @override
  String get enterCurrentPin => 'Entrez votre PIN actuel';

  @override
  String get newPin => 'Nouveau PIN';

  @override
  String get changePin => 'Modifier';

  @override
  String get pinChangedSuccess => 'PIN modifié avec succès';

  @override
  String get removePin => 'Supprimer le code PIN';

  @override
  String get removePinConfirm =>
      'Cela supprimera votre code PIN. Vous pouvez en configurer un nouveau à tout moment.';

  @override
  String get verifyPin => 'Vérifier le PIN';

  @override
  String get enterPinToRemove => 'Entrez votre PIN pour confirmer';

  @override
  String get pinRemovedSuccess => 'Code PIN supprimé';

  @override
  String get pinMustBe6Digits => 'Le PIN doit contenir 6 chiffres';

  @override
  String get incorrectPin => 'PIN incorrect';

  @override
  String get confirmPin => 'Confirmer';

  @override
  String get pinsDoNotMatch => 'Les PINs ne correspondent pas';

  @override
  String get pinEnabled => 'Activé';

  @override
  String get pinNotSet => 'Non configuré';

  @override
  String get pinEnabledDescription =>
      'Votre compte est protégé par un PIN à 6 chiffres.';

  @override
  String get pinDescription =>
      'Configurez un PIN à 6 chiffres comme méthode de secours pour déverrouiller l\'application.';

  @override
  String get enterPinToUnlock => 'Entrez votre PIN pour déverrouiller';

  @override
  String get devicePasskey => 'Clé d\'accès';

  @override
  String get passkeyShortDesc => 'Connexion sans mot de passe';

  @override
  String get twoFactorAuth => 'Authentification à deux facteurs';

  @override
  String get authenticatorApp => 'Application d\'authentification';

  @override
  String get twoFADescription =>
      'Utilisez une application comme Google Authenticator ou Authy pour une sécurité supplémentaire.';

  @override
  String get twoFAShortDesc => 'Google Authenticator, Authy';

  @override
  String get setup2FA => 'Configurer 2FA';

  @override
  String get pinRequiredForFaceId => 'Veuillez d\'abord configurer le code PIN';

  @override
  String get requiresPinFirst => 'Nécessite un code PIN';

  @override
  String get pinFirst => 'PIN d\'abord';

  @override
  String get securityInfoShort =>
      'Configurez d\'abord le PIN, puis activez Face ID pour un déverrouillage rapide. Le PIN est votre secours.';

  @override
  String get failedToSetupPin => 'Échec de la configuration du PIN';

  @override
  String get failedToChangePin => 'Échec de la modification du PIN';

  @override
  String get failedToRemovePin => 'Échec de la suppression du PIN';

  @override
  String get failedToUpdateBiometric =>
      'Échec de la mise à jour des paramètres biométriques';

  @override
  String get orDivider => 'OU';

  @override
  String get codeExpiresAfterUse =>
      'Le code expire après la première utilisation';

  @override
  String get signInFailed => 'Échec de la connexion';

  @override
  String get signUpFailed => 'Échec de l\'inscription';

  @override
  String get signOutFailed => 'Échec de la déconnexion';

  @override
  String get googleSignInFailed => 'Échec de la connexion Google';

  @override
  String get googleSignUpFailed => 'Échec de l\'inscription Google';

  @override
  String get reenterPinToConfirm => 'Ressaisissez votre PIN pour confirmer';

  @override
  String get continueText => 'Continuer';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get soon => 'Bientôt';

  @override
  String get featureComingSoon => 'Cette fonctionnalité arrive bientôt!';

  @override
  String get useAnotherMethod => 'Utiliser une autre méthode';

  @override
  String get unlockOptions => 'Options de déverrouillage';

  @override
  String get chooseUnlockMethod => 'Choisissez comment déverrouiller';

  @override
  String get tryFaceIdAgain => 'Réessayer Face ID';

  @override
  String get usePasskey => 'Utiliser le passkey';

  @override
  String get use2FACode => 'Utiliser le code 2FA';

  @override
  String get enter2FACode => 'Entrez le code 2FA';

  @override
  String get enter6DigitCode => 'Entrez le code à 6 chiffres de votre app';

  @override
  String get verifyCode => 'Vérifier le code';

  @override
  String get invalidCode => 'Code invalide. Veuillez réessayer.';

  @override
  String get twoFAEnabled => 'Activé';

  @override
  String get twoFADisabled => '2FA désactivé';

  @override
  String get disable => 'Désactiver';

  @override
  String get disable2FA => 'Désactiver 2FA';

  @override
  String get pinRequiredFor2FA => 'Veuillez d\'abord configurer le code PIN';

  @override
  String get enterSixDigitCode => 'Veuillez entrer le code à 6 chiffres';

  @override
  String get enterCodeToDisable2FA =>
      'Entrez le code de votre application d\'authentification pour confirmer';

  @override
  String get twoFactorEnabled => 'Authentification à deux facteurs activée !';

  @override
  String get secretCopied => 'Clé secrète copiée dans le presse-papiers';

  @override
  String get scanQrCode => 'Scanner ce code QR';

  @override
  String get useAuthenticatorApp =>
      'Ouvrez votre application d\'authentification et scannez ce code QR pour ajouter votre compte';

  @override
  String get orText => 'ou';

  @override
  String get enterManually => 'Entrer cette clé manuellement';

  @override
  String get copySecretKey => 'Copier la clé secrète';

  @override
  String get authenticatorAccountInfo =>
      'Le nom du compte dans votre application d\'authentification sera votre adresse email';

  @override
  String get enterVerificationCode => 'Entrer le code de vérification';

  @override
  String get enterCodeFromAuthenticator =>
      'Entrez le code à 6 chiffres de votre application d\'authentification pour terminer la configuration';

  @override
  String get codeRefreshesEvery30Seconds =>
      'Les codes se rafraîchissent toutes les 30 secondes. Assurez-vous d\'entrer le code actuel.';

  @override
  String get activateTwoFactor => 'Activer 2FA';

  @override
  String get noInternetConnection => 'Pas de connexion Internet';

  @override
  String get offlineMessage =>
      'Veuillez vérifier votre connexion Internet et réessayer. Vous devez être connecté pour utiliser cette application.';

  @override
  String get connectionTip =>
      'Astuce: Essayez d\'activer le Wi-Fi ou les données mobiles';

  @override
  String get closeApp => 'Fermer l\'application';

  @override
  String get retryHint =>
      'L\'application se reconnectera automatiquement en ligne';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordDesc =>
      'Mettre à jour le mot de passe de votre compte';

  @override
  String get changePasswordDialogDesc =>
      'Entrez votre mot de passe actuel et choisissez-en un nouveau';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get currentPasswordRequired => 'Le mot de passe actuel est requis';

  @override
  String get passwordDoesNotMeetRequirements =>
      'Le mot de passe ne répond pas aux exigences';

  @override
  String get newPasswordMustBeDifferent =>
      'Le nouveau mot de passe doit être différent de l\'actuel';

  @override
  String get passwordChangedSuccess => 'Mot de passe changé avec succès';

  @override
  String get failedToChangePassword => 'Échec du changement de mot de passe';

  @override
  String get createPassword => 'Créer un mot de passe';

  @override
  String get createPasswordDesc => 'Créez un mot de passe pour votre compte';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordCreatedSuccess => 'Mot de passe créé avec succès';

  @override
  String get failedToCreatePassword => 'Échec de la création du mot de passe';

  @override
  String get alternativeUnlock => 'Déverrouillage alternatif';

  @override
  String get chooseSecureMethod => 'Choisissez une méthode sécurisée';

  @override
  String get authenticatorCode => 'Code d\'authentification';

  @override
  String get markAllRead => 'Tout marquer lu';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get noNotificationsDesc =>
      'Les mises à jour importantes apparaîtront ici';

  @override
  String get allNotificationsRead =>
      'Toutes les notifications marquées comme lues';

  @override
  String get completeProfile => 'Compléter le profil';

  @override
  String get setupSecurity => 'Configurer sécurité';

  @override
  String get viewDetails => 'Voir détails';

  @override
  String get notificationWelcomeTitle => 'Bienvenue sur Cha9cha9ni';

  @override
  String get notificationWelcomeMessage =>
      'Nous sommes ravis de vous accueillir dans notre communauté ! Si vous avez besoin d\'aide, n\'hésitez pas à contacter notre équipe de support à support@cha9cha9ni.tn ou utilisez l\'option Aide dans le menu.';

  @override
  String get notificationProfileTitle => 'Complétez votre profil';

  @override
  String get notificationProfileMessage =>
      'Pour effectuer des retraits et accéder à toutes nos fonctionnalités, veuillez compléter vos informations personnelles dans les paramètres de votre profil. Cela nous aide à vérifier votre identité et à sécuriser votre compte.';

  @override
  String get notificationSecurityTitle => 'Sécurisez votre compte';

  @override
  String get notificationSecurityMessage =>
      'Protégez votre compte en activant l\'authentification à deux facteurs (2FA) et en configurant un code PIN. Cela vous aidera à protéger vos données et transactions contre tout accès non autorisé.';

  @override
  String get read => 'Lu';

  @override
  String get noRecentActivities => 'Aucune activité récente';

  @override
  String get wantsToRemoveYou => 'Veut vous retirer';

  @override
  String ownerRequestedRemoval(String ownerName) {
    return '$ownerName a demandé à vous retirer de la famille';
  }

  @override
  String get respond => 'Répondre';

  @override
  String get signingYouIn => 'Connexion en cours...';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minAgo(int count) {
    return 'Il y a $count min';
  }

  @override
  String minsAgo(int count) {
    return 'Il y a $count mins';
  }

  @override
  String hourAgo(int count) {
    return 'Il y a $count heure';
  }

  @override
  String hoursAgo(int count) {
    return 'Il y a $count heures';
  }

  @override
  String dayAgo(int count) {
    return 'Il y a $count jour';
  }

  @override
  String daysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String monthAgo(int count) {
    return 'Il y a $count mois';
  }

  @override
  String monthsAgo(int count) {
    return 'Il y a $count mois';
  }

  @override
  String get loading => 'Chargement...';

  @override
  String get scanCode => 'Utiliser une carte cadeau';

  @override
  String get cameraPermissionRequired => 'Autorisation de la caméra requise';

  @override
  String get cameraPermissionDescription =>
      'Nous avons besoin d\'accéder à la caméra pour scanner les codes de cartes cadeaux et les codes QR.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get pointCameraAtCode =>
      'Pointez la caméra vers le code de la carte cadeau';

  @override
  String get enterCodeManually => 'Entrer le code manuellement';

  @override
  String get scanInstead => 'Scanner à la place';

  @override
  String get enterCodeDescription =>
      'Entrez le code de la carte cadeau pour ajouter du solde à votre compte';

  @override
  String get invalidCodeFormat =>
      'Veuillez entrer un code de remboursement valide';

  @override
  String get codeScanned => 'Code scanné!';

  @override
  String get joinFamily => 'Utiliser';

  @override
  String get rewardsPoints => 'points';

  @override
  String get rewardsStreak => 'Série';

  @override
  String get rewardsAds => 'Pubs';

  @override
  String get rewardsDailyCheckIn => 'Connexion quotidienne';

  @override
  String rewardsDayStreak(int count) {
    return 'Série de $count jours!';
  }

  @override
  String rewardsClaimPoints(int points) {
    return 'Réclamer +$points pts';
  }

  @override
  String get rewardsClaimed => 'Réclamé';

  @override
  String get rewardsNextIn => 'Prochain dans';

  @override
  String get rewardsWatchAndEarn => 'Regarder et Gagner';

  @override
  String rewardsWatchAdToEarn(int points) {
    return 'Regardez une pub pour gagner +$points pts';
  }

  @override
  String get rewardsAllAdsWatched => 'Toutes les pubs vues aujourd\'hui!';

  @override
  String get rewardsRedeemRewards => 'Échanger les récompenses';

  @override
  String get rewardsConvertPoints => 'Convertir les points en TND';

  @override
  String get rewardsRedeem => 'Échanger';

  @override
  String get rewardsComingSoon => 'Bientôt disponible!';

  @override
  String rewardsRedeemingFor(String name, String points) {
    return 'L\'échange de $name pour $points points sera bientôt disponible!';
  }

  @override
  String get rewardsGotIt => 'Compris!';

  @override
  String get rewardsSimulatedAd => 'Pub simulée';

  @override
  String get rewardsSimulatedAdDesc =>
      'En production, une vraie pub avec récompense serait diffusée ici.';

  @override
  String get rewardsSkipAd => 'Passer la pub';

  @override
  String get rewardsWatchComplete => 'Visionnage terminé';

  @override
  String get rewardsPointsEarned => 'Points gagnés!';

  @override
  String get rewardsAdReward => 'Récompense pub';

  @override
  String get rewardsDailyReward => 'Récompense quotidienne';

  @override
  String get rewardsLoadingAd => 'Chargement de la pub...';

  @override
  String get rewardsCheckInSuccess => 'Connexion réussie!';

  @override
  String get rewardsCheckInFailed =>
      'Échec de la connexion. Veuillez réessayer.';

  @override
  String get rewardsClaimFailed =>
      'Échec de la réclamation. Veuillez réessayer.';

  @override
  String get rewardsAdFailed =>
      'La pub n\'a pas pu s\'afficher. Veuillez réessayer.';

  @override
  String get allActivities => 'Toutes les activités';

  @override
  String get activitiesWillAppearHere =>
      'Les activités familiales apparaîtront ici quand les membres gagnent des points';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String activityWatchedAd(String name) {
    return '$name a regardé une pub';
  }

  @override
  String activityDailyCheckIn(String name) {
    return '$name a réclamé la connexion quotidienne';
  }

  @override
  String activityTopUp(String name) {
    return '$name a rechargé';
  }

  @override
  String activityReferral(String name) {
    return 'Bonus de parrainage de $name';
  }

  @override
  String activityEarnedPoints(String name) {
    return '$name a gagné des points';
  }

  @override
  String get filterActivities => 'Filtrer les activités';

  @override
  String get filterByTime => 'Par période';

  @override
  String get filterByType => 'Par type d\'activité';

  @override
  String get filterByMember => 'Filtrer par membre';

  @override
  String get showOnlyMyActivities => 'Afficher uniquement mes activités';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterLast10Days => '10 derniers jours';

  @override
  String get filterLast7Days => '7 derniers jours';

  @override
  String get filterLast30Days => '30 derniers jours';

  @override
  String get filterLast3Months => '3 derniers mois';

  @override
  String get filterAllTypes => 'Tous les types';

  @override
  String get filterAds => 'Publicités';

  @override
  String get filterCheckIn => 'Check-in';

  @override
  String get filterTopUp => 'Recharge';

  @override
  String get filterReferral => 'Parrainage';

  @override
  String get filterOther => 'Autre';

  @override
  String get applyFilters => 'Appliquer';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get noActivitiesForFilter =>
      'Aucune activité ne correspond à vos filtres';

  @override
  String get usageAndLimits => 'Utilisation et Limites';

  @override
  String ownerPlusMembers(int count) {
    return 'Propriétaire + $count membres';
  }

  @override
  String get withdrawAccess => 'Accès au Retrait';

  @override
  String get ownerOnlyCanWithdraw => 'Seul le propriétaire peut retirer';

  @override
  String get youAreOwner => 'Vous êtes le propriétaire de la famille';

  @override
  String get onlyOwnerCanWithdrawDescription =>
      'Seul le propriétaire de la famille peut retirer des fonds';

  @override
  String get kycVerified => 'Identité vérifiée';

  @override
  String get kycRequired => 'Vérification KYC requise pour retirer';

  @override
  String get verifyIdentity => 'Vérifier l\'identité';

  @override
  String get selectedAid => 'Aide Sélectionnée';

  @override
  String get selectAnAid => 'Appuyez pour sélectionner une aide';

  @override
  String maxDT(int amount) {
    return 'Max $amount DT';
  }

  @override
  String get adsToday => 'Publicités Aujourd\'hui';

  @override
  String adsPerMember(int count) {
    return '$count pubs / membre';
  }

  @override
  String get watched => 'vues';

  @override
  String get adsDescription =>
      'Regardez des publicités pour gagner des points pour votre épargne familiale';

  @override
  String get unlockMoreBenefits =>
      'Passez à un pack supérieur pour débloquer plus d\'avantages, de retraits et d\'aides';

  @override
  String get changeMyPack => 'Changer mon pack';

  @override
  String get free => 'Gratuit';

  @override
  String get month => 'mois';

  @override
  String get year => 'an';

  @override
  String get monthly => 'Mensuel';

  @override
  String get yearly => 'Annuel';

  @override
  String upToAmount(int amount) {
    return 'Jusqu\'à $amount DT au total';
  }

  @override
  String withdrawalsPerYear(int count) {
    return '$count retraits / an';
  }

  @override
  String get allPacks => 'Tous les Packs';

  @override
  String get choosePack => 'Choisissez Votre Pack';

  @override
  String get choosePackDescription =>
      'Sélectionnez le pack qui correspond le mieux aux besoins de votre famille';

  @override
  String minimumWithdrawal(int amount) {
    return 'Le montant minimum de retrait est de $amount DT';
  }

  @override
  String familyMembersCount(int count) {
    return '$count membres de famille';
  }

  @override
  String aidsSelectable(int count) {
    return '$count aides sélectionnables';
  }

  @override
  String get currentPack => 'Pack Actuel';

  @override
  String get selectPack => 'Sélectionner le Pack';

  @override
  String upgradeTo(String name) {
    return 'Passer à $name';
  }

  @override
  String downgradeTo(String name) {
    return 'Rétrograder vers $name';
  }

  @override
  String get downgradeConfirmation =>
      'Êtes-vous sûr de vouloir passer au pack Gratuit ? Vous pourriez perdre l\'accès à certaines fonctionnalités.';

  @override
  String upgradeConfirmation(String name, int price) {
    return 'Passer à $name pour $price DT/mois ?';
  }

  @override
  String get confirmSelection => 'Confirm Selection';

  @override
  String get subscriptionComingSoon =>
      'Gestion des abonnements bientôt disponible !';

  @override
  String get selectAid => 'Sélectionner une Aide';

  @override
  String get tunisianAids => 'Aides Tunisiennes';

  @override
  String selectionsRemaining(int remaining, int total) {
    return '$remaining sur $total sélections disponibles';
  }

  @override
  String get aidSelectionDescription =>
      'Sélectionnez votre aide préférée pour le retrait. Chaque aide a des fenêtres de retrait et des montants maximum spécifiques.';

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
  String get yourSelectedAids => 'Vos Aides Sélectionnées';

  @override
  String get availableAids => 'Aides Disponibles';

  @override
  String get selected => 'Sélectionné';

  @override
  String get maxWithdrawal => 'Retrait max';

  @override
  String get window => 'Période';

  @override
  String get select => 'Sélectionner';

  @override
  String get aidAlreadySelected => 'Cette aide est déjà sélectionnée';

  @override
  String maxAidsReached(int count) {
    return 'Vous ne pouvez sélectionner que $count aide(s) avec votre pack actuel';
  }

  @override
  String get selectAidConfirmTitle => 'Confirmer la Sélection';

  @override
  String selectAidConfirmMessage(String name) {
    return 'Êtes-vous sûr de vouloir sélectionner $name ?';
  }

  @override
  String get aidSelectionWarning =>
      'Vous ne pouvez pas changer votre aide sélectionnée sans contacter le support';

  @override
  String aidSelectedSuccess(String name) {
    return '$name a été sélectionnée avec succès';
  }

  @override
  String get viewOnlyPackInfo =>
      'Seul le propriétaire de la famille peut gérer le pack et les aides';

  @override
  String get noAidSelected => 'Aucune aide sélectionnée';

  @override
  String daysUntilAid(int days, String aidName) {
    return '$days jours avant $aidName';
  }

  @override
  String get aidWindowOpen => 'La fenêtre de retrait est ouverte !';

  @override
  String aidWindowClosed(int days) {
    return 'Fenêtre ouvre dans $days jours';
  }

  @override
  String get leaveFamilyTitle => 'Quitter la famille';

  @override
  String get leaveFamilyConfirmMessage =>
      'Êtes-vous sûr de vouloir quitter cette famille ? Vos points resteront avec votre famille actuelle et vous recommencerez à zéro si vous rejoignez une nouvelle famille.';

  @override
  String get leaveFamilyWarning => 'Cette action est irréversible';

  @override
  String get leave => 'Leave';

  @override
  String get leaveFamilyCodeSent => 'Code de confirmation envoyé à votre email';

  @override
  String get leaveFamilySuccess => 'Vous avez quitté la famille avec succès';

  @override
  String get leaveFamilyConfirmTitle => 'Confirmer le départ';

  @override
  String get leaveFamilyCodePrompt =>
      'Entrez le code à 6 chiffres envoyé à votre email pour confirmer';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get resendCodeIn => 'Renvoyer le code dans';

  @override
  String get codeSentAgain => 'Code renvoyé';

  @override
  String tooManyAttempts(Object minutes) {
    return 'Trop de tentatives. Veuillez réessayer dans $minutes minutes.';
  }

  @override
  String get tooManyAttemptsTitle => 'Trop de tentatives';

  @override
  String rateLimitedWait(String time) {
    return 'Limite atteinte. Veuillez patienter $time';
  }

  @override
  String tooManyRefreshes(int minutes) {
    return 'Trop de rafraîchissements. Veuillez patienter $minutes minutes.';
  }

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get statementTitle => 'Relevé';

  @override
  String get statementSubtitle =>
      'Sélectionnez une date de début pour générer votre relevé et le recevoir par email';

  @override
  String get statementSelectStartDate => 'Sélectionner la Date de Début';

  @override
  String get statementDateHint => 'Relevé de cette date jusqu\'à aujourd\'hui';

  @override
  String get statementYear => 'Année';

  @override
  String get statementMonth => 'Mois';

  @override
  String get statementPeriod => 'Période du Relevé';

  @override
  String get statementToday => 'Aujourd\'hui';

  @override
  String get statementSelectDate => 'Veuillez sélectionner une date';

  @override
  String get statementNoActivity =>
      'Aucune activité trouvée pour cette période. Veuillez sélectionner une autre date.';

  @override
  String get statementLoadError =>
      'Échec du chargement des données. Veuillez réessayer.';

  @override
  String get statementGenerateError =>
      'Échec de la génération du relevé. Veuillez réessayer.';

  @override
  String get statementSending => 'Envoi en cours...';

  @override
  String get statementSendButton => 'Envoyer à Mon Email';

  @override
  String get statementRateLimitError =>
      'Limite atteinte ! Vous ne pouvez envoyer que 2 relevés par jour.';

  @override
  String get statementRateLimitNote => 'Limité à 2 envois par jour';

  @override
  String statementRemainingEmails(int count) {
    return '$count envoi(s) restant(s) aujourd\'hui';
  }

  @override
  String get statementSentTitle => 'Relevé Envoyé!';

  @override
  String statementSentDescription(String startDate) {
    return 'Votre relevé du $startDate à aujourd\'hui a été envoyé à';
  }

  @override
  String get statementGotIt => 'Compris!';
}
