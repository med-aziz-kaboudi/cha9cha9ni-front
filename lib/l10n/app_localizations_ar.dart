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
}
