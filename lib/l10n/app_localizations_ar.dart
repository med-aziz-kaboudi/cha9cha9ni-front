// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcomeBack => 'مرحبا بعودتك';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟ ';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get firstName => 'الاسم الأول *';

  @override
  String get lastName => 'اسم العائلة *';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني *';

  @override
  String get phoneNumber => 'رقم الهاتف *';

  @override
  String get enterPassword => 'أدخل كلمة المرور *';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get orSignInWith => 'أو سجل الدخول باستخدام';

  @override
  String get orSignUpWith => 'أو أنشئ حساباً باستخدام';

  @override
  String get signInWithGoogle => 'تسجيل الدخول باستخدام جوجل';

  @override
  String get signUpWithGoogle => 'إنشاء حساب باستخدام جوجل';

  @override
  String get passwordRequirement1 => 'يجب أن تحتوي على 8 أحرف على الأقل';

  @override
  String get passwordRequirement2 => 'تحتوي على رقم';

  @override
  String get passwordRequirement3 => 'تحتوي على حرف كبير';

  @override
  String get passwordRequirement4 => 'تحتوي على رمز خاص';

  @override
  String termsAgreement(String action) {
    return 'بالنقر على \"$action\" فإنك توافق على ';
  }

  @override
  String get termOfUse => 'شروط الاستخدام ';

  @override
  String get and => 'و ';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get skip => 'تخطي';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get onboarding1Title => 'التوفير يصبح أفضل\nعندما نقوم به\nمعًا';

  @override
  String get onboarding1Description =>
      'اجمع عائلتك في مساحة واحدة مشتركة وعزز مدخراتك خطوة بخطوة.';

  @override
  String get onboarding2Title => 'وفّر\nللحظات التي\nتهمك';

  @override
  String get onboarding2Description =>
      'التخطيط المدروس للحظات المميزة، يجلب السلام والفرح لعائلتك.';

  @override
  String get otpVerification => 'التحقق من الرمز';

  @override
  String get verifyEmailSubtitle => 'نحتاج للتحقق من بريدك الإلكتروني';

  @override
  String get verifyEmailDescription =>
      'للتحقق من حسابك، أدخل رمز التحقق المكون من 6 أرقام الذي أرسلناه إلى بريدك الإلكتروني.';

  @override
  String get verify => 'تحقق';

  @override
  String get resendOTP => 'إعادة إرسال الرمز';

  @override
  String get resendOtp => 'إعادة إرسال الرمز';

  @override
  String resendOTPIn(String seconds) {
    return 'إعادة إرسال الرمز خلال $seconds ثانية';
  }

  @override
  String get codeExpiresInfo => 'ينتهي صلاحية الرمز خلال 15 دقيقة';

  @override
  String get enterAllDigits => 'الرجاء إدخال جميع الأرقام الستة';

  @override
  String get emailVerifiedSuccess => '✅ تم التحقق من البريد الإلكتروني بنجاح!';

  @override
  String verificationFailed(String error) {
    return 'فشل التحقق: $error';
  }

  @override
  String get verificationSuccess => 'تم التحقق بنجاح!';

  @override
  String get verificationSuccessSubtitle =>
      'تم التحقق من بريدك الإلكتروني بنجاح. يمكنك الآن الوصول إلى جميع الميزات.';

  @override
  String get okay => 'حسناً';

  @override
  String pleaseWaitSeconds(String seconds) {
    return 'يرجى الانتظار $seconds ثانية قبل طلب رمز جديد';
  }

  @override
  String get emailAlreadyVerified => 'البريد الإلكتروني مُفعّل بالفعل';

  @override
  String get userNotFound => 'المستخدم غير موجود';

  @override
  String get invalidVerificationCode => 'رمز التحقق غير صحيح';

  @override
  String get verificationCodeExpired =>
      'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.';

  @override
  String get noVerificationCode => 'لا يوجد رمز تحقق. يرجى طلب رمز جديد.';

  @override
  String get registrationSuccessful =>
      'تم التسجيل بنجاح! يرجى تسجيل الدخول للتحقق من بريدك الإلكتروني.';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmYourPassword => 'أكد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get confirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordResetSuccessfully =>
      'تم إعادة تعيين كلمة المرور بنجاح! يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.';

  @override
  String get checkYourMailbox => 'تفقد بريدك الإلكتروني';

  @override
  String weHaveSentResetCodeTo(String email) {
    return 'لقد أرسلنا رمز إعادة التعيين المكون من 6 أرقام إلى $email';
  }

  @override
  String get pleaseEnterEmail => 'يرجى إدخال عنوان بريدك الإلكتروني';

  @override
  String get invalidEmailFormat => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get pleaseEnterComplete6DigitCode =>
      'يرجى إدخال الرمز المكون من 6 أرقام كاملاً';

  @override
  String get codeSentSuccessfully =>
      'تم إرسال الرمز بنجاح! يرجى التحقق من بريدك الإلكتروني.';

  @override
  String get anErrorOccurred => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get didntReceiveCode => 'لم تتلق الرمز؟';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordMinLength =>
      'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get joinOrCreateFamily => 'انضم أو أنشئ عائلة';

  @override
  String get chooseHowToProceed => 'اختر كيف تريد المتابعة';

  @override
  String get createAFamily => 'إنشاء عائلة';

  @override
  String get joinAFamily => 'الانضمام لعائلة';

  @override
  String get enterInviteCode => 'XXXX-XXXX';

  @override
  String get pleaseEnterInviteCode => 'الرجاء إدخال رمز الدعوة';

  @override
  String get failedToCreateFamily => 'فشل إنشاء العائلة';

  @override
  String get failedToJoinFamily => 'فشل الانضمام للعائلة';

  @override
  String get joinNow => 'انضم الآن';

  @override
  String get cancel => 'إلغاء';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get familyInviteCode => 'رمز دعوة العائلة';

  @override
  String get shareThisCode =>
      'شارك هذا الرمز مع أفراد عائلتك حتى يتمكنوا من الانضمام';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get codeCopied => 'تم نسخ رمز الدعوة!';

  @override
  String get gotIt => 'فهمت!';

  @override
  String get welcomeFamilyOwner => 'مرحباً، مالك العائلة!';

  @override
  String get welcomeFamilyMember => 'مرحباً، عضو العائلة!';

  @override
  String get yourFamily => 'عائلتك';

  @override
  String get owner => 'المالك';

  @override
  String get members => 'الأعضاء';

  @override
  String get noCodeAvailable => 'لا يوجد رمز متاح';

  @override
  String get inviteCodeCopiedToClipboard => 'تم نسخ رمز الدعوة!';

  @override
  String get shareCodeWithFamilyMembers =>
      'شارك هذا الرمز مع أفراد العائلة.\nسيتغير بعد كل استخدام.';

  @override
  String get scanButtonTapped => 'تم النقر على زر المسح';

  @override
  String get rewardScreenComingSoon => 'شاشة المكافآت قريباً';

  @override
  String get home => 'الرئيسية';

  @override
  String get reward => 'المكافآت';

  @override
  String get myFamily => 'عائلتي';
}
