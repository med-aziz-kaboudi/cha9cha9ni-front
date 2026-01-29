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
  String get passwordStrong => 'كلمة مرور قوية!';

  @override
  String get passwordRequirements => 'متطلبات كلمة المرور';

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
  String get enterInviteCode => 'أدخل رمز الاستبدال';

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

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get yourCurrentPack => 'باقتك الحالية';

  @override
  String get loginAndSecurity => 'تسجيل الدخول والأمان';

  @override
  String get languages => 'اللغات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get help => 'المساعدة';

  @override
  String get legalAgreements => 'الاتفاقيات القانونية';

  @override
  String get leaveFamily => 'مغادرة العائلة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get balance => 'الرصيد';

  @override
  String get topUp => 'شحن';

  @override
  String get withdraw => 'سحب';

  @override
  String get statement => 'كشف الحساب';

  @override
  String get nextWithdrawal => 'السحب القادم';

  @override
  String availableInDays(int days) {
    return 'متاح خلال $days يوم';
  }

  @override
  String get familyMembers => 'أفراد العائلة';

  @override
  String get manage => 'إدارة >';

  @override
  String get recentActivities => 'الأنشطة الأخيرة :';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get googleSignInCancelled => 'تم إلغاء تسجيل الدخول';

  @override
  String get googleSignInCancelledMessage =>
      'لقد ألغيت تسجيل الدخول باستخدام Google. يرجى المحاولة مرة أخرى للمتابعة.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get close => 'إغلاق';

  @override
  String get pts => 'نقطة';

  @override
  String get sessionExpiredTitle => 'انتهت الجلسة';

  @override
  String get sessionExpiredMessage =>
      'تم تسجيل الدخول من جهاز آخر إلى حسابك. سيتم تسجيل خروجك لأسباب أمنية.';

  @override
  String get ok => 'حسناً';

  @override
  String get skipTutorial => 'تخطي الدليل';

  @override
  String get nextTutorial => 'التالي';

  @override
  String get doneTutorial => 'فهمت!';

  @override
  String get tutorialSidebarTitle => 'القائمة';

  @override
  String get tutorialSidebarDesc =>
      'اضغط هنا لفتح القائمة الجانبية. الوصول إلى ملفك الشخصي والإعدادات والمزيد.';

  @override
  String get tutorialTopUpTitle => 'إضافة رصيد';

  @override
  String get tutorialTopUpDesc =>
      'أضف المال إلى حساب العائلة. شارك الأموال مع أفراد عائلتك بسهولة.';

  @override
  String get tutorialWithdrawTitle => 'سحب';

  @override
  String get tutorialWithdrawDesc =>
      'اطلب سحب المال من مدخرات عائلتك عند الحاجة.';

  @override
  String get tutorialStatementTitle => 'كشف الحساب';

  @override
  String get tutorialStatementDesc =>
      'عرض سجل جميع معاملاتك. تتبع إنفاق ومدخرات عائلتك.';

  @override
  String get tutorialPointsTitle => 'نقاط المكافآت';

  @override
  String get tutorialPointsDesc =>
      'اكسب نقاطاً مع كل نشاط! استبدلها بمكافآت ومزايا حصرية.';

  @override
  String get tutorialNotificationTitle => 'الإشعارات';

  @override
  String get tutorialNotificationDesc =>
      'ابق على اطلاع بأنشطة العائلة والمعاملات والتنبيهات المهمة.';

  @override
  String get tutorialQrCodeTitle => 'ماسح QR';

  @override
  String get tutorialQrCodeDesc =>
      'امسح رموز QR لإجراء مدفوعات سريعة أو إضافة أفراد جدد للعائلة.';

  @override
  String get tutorialRewardTitle => 'المكافآت';

  @override
  String get tutorialRewardDesc =>
      'استكشف واستبدل نقاطك المكتسبة بمكافآت وخصومات رائعة.';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get firstNameLabel => 'الاسم الأول';

  @override
  String get lastNameLabel => 'اسم العائلة';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get firstNameRequired => 'الاسم الأول مطلوب';

  @override
  String get lastNameRequired => 'اسم العائلة مطلوب';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get edit => 'تعديل';

  @override
  String get changeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get verifyCurrentEmailDesc =>
      'لتغيير بريدك الإلكتروني، نحتاج أولاً للتحقق من بريدك الإلكتروني الحالي.';

  @override
  String get sendVerificationCode => 'إرسال رمز التحقق';

  @override
  String enterCodeSentTo(String email) {
    return 'أدخل الرمز المكون من 6 أرقام المرسل إلى $email';
  }

  @override
  String get currentEmailVerified => 'تم التحقق من البريد الإلكتروني الحالي';

  @override
  String get enterNewEmail => 'أدخل عنوان بريدك الإلكتروني الجديد';

  @override
  String get newEmailPlaceholder => 'newemail@example.com';

  @override
  String get confirmChange => 'تأكيد التغيير';

  @override
  String get emailUpdatedSuccessfully => 'تم تحديث البريد الإلكتروني بنجاح!';

  @override
  String get phoneNumberMustBe8Digits =>
      'يجب أن يتكون رقم الهاتف من 8 أرقام بالضبط';

  @override
  String get phoneNumberAlreadyInUse => 'رقم الهاتف هذا مستخدم بالفعل';

  @override
  String get addMember => 'إضافة عضو';

  @override
  String get shareInviteCodeDesc =>
      'شارك هذا الرمز مع أحد أفراد عائلتك لإضافته';

  @override
  String get copy => 'نسخ';

  @override
  String get noMembersYet => 'لا يوجد أعضاء بعد';

  @override
  String get tapAddMemberToInvite => 'اضغط على \"إضافة عضو\" لدعوة عائلتك';

  @override
  String get removeMember => 'إزالة العضو';

  @override
  String removeMemberConfirm(String name) {
    return 'هل أنت متأكد أنك تريد إزالة $name من العائلة؟';
  }

  @override
  String get remove => 'حذف';

  @override
  String get confirmRemoval => 'تأكيد الإزالة';

  @override
  String get enterCodeSentToEmail =>
      'أدخل رمز التحقق المرسل إلى بريدك الإلكتروني';

  @override
  String get enterValidCode => 'أدخل رمزًا صالحًا مكونًا من 6 أرقام';

  @override
  String removalInitiated(String name) {
    return 'تم إرسال طلب الإزالة إلى $name';
  }

  @override
  String get acceptRemoval => 'قبول الإزالة';

  @override
  String acceptRemovalConfirm(String name) {
    return '$name يريد إزالتك من العائلة. هل توافق؟';
  }

  @override
  String get decline => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get confirmLeave => 'تأكيد المغادرة';

  @override
  String get removedFromFamily => 'تمت الإزالة من العائلة';

  @override
  String get removedFromFamilyDesc =>
      'تمت إزالتك من العائلة بنجاح. يمكنك الآن الانضمام أو إنشاء عائلة جديدة.';

  @override
  String get removalRequestTitle => 'طلب إزالة';

  @override
  String removalRequestDesc(String name) {
    return '$name يريد إزالتك من العائلة.';
  }

  @override
  String get viewRequest => 'عرض الطلب';

  @override
  String get verificationCodeWillBeSent =>
      'سيتم إرسال رمز التحقق إلى بريدك الإلكتروني';

  @override
  String get pendingRemovalRequests => 'طلبات الإزالة المعلقة';

  @override
  String get cancelRemovalRequest => 'إلغاء الطلب';

  @override
  String cancelRemovalConfirm(String name) {
    return 'هل أنت متأكد أنك تريد إلغاء طلب الإزالة لـ $name؟';
  }

  @override
  String get removalCancelled => 'تم إلغاء طلب الإزالة';

  @override
  String get waitingForMemberConfirmation => 'في انتظار تأكيد العضو';

  @override
  String get pendingRemoval => 'معلق';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get choosePreferredLanguage => 'اختر لغتك المفضلة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageChanged => 'تم تغيير اللغة بنجاح';

  @override
  String get currentLanguage => 'الحالية';

  @override
  String get loginSecurity => 'تسجيل الدخول والأمان';

  @override
  String get securityDescription =>
      'أضف طبقة حماية إضافية لحماية حسابك وبيانات عائلتك.';

  @override
  String get passkey => 'رمز الدخول';

  @override
  String get sixDigitPasskey => 'رمز من 6 أرقام';

  @override
  String get passkeyEnabled => 'مفعّل';

  @override
  String get passkeyNotSet => 'غير مُعدّ';

  @override
  String get passkeyEnabledDescription => 'حسابك محمي برمز من 6 أرقام.';

  @override
  String get passkeyDescription =>
      'احفظ هذا الجهاز لتسجيل الدخول بدون كلمة مرور. مثل PayPal و Wise، ستتمكن من تسجيل الدخول فوراً.';

  @override
  String get setupPasskey => 'إعداد مفتاح المرور';

  @override
  String get changePasskey => 'تغيير';

  @override
  String get removePasskey => 'حذف الرمز';

  @override
  String get removePasskeyConfirm =>
      'سيؤدي هذا أيضًا إلى تعطيل المصادقة البيومترية. ستحتاج إلى إعداد رمز جديد لإعادة تفعيل ميزات الأمان.';

  @override
  String get verifyPasskey => 'التحقق من الرمز';

  @override
  String get enterPasskeyToRemove => 'أدخل رمزك لتأكيد الحذف';

  @override
  String get currentPasskey => 'الرمز الحالي';

  @override
  String get enterCurrentPasskey => 'أدخل رمزك الحالي';

  @override
  String get newPasskey => 'الرمز الجديد';

  @override
  String get enterNewPasskey => 'أدخل رمزك الجديد المكون من 6 أرقام';

  @override
  String get confirmPasskey => 'تأكيد الرمز';

  @override
  String get passkeyMustBe6Digits => 'يجب أن يتكون الرمز من 6 أرقام';

  @override
  String get passkeysDoNotMatch => 'الرموز غير متطابقة';

  @override
  String get passkeySetupSuccess => 'تم إعداد الرمز بنجاح';

  @override
  String get passkeyChangedSuccess => 'تم تغيير الرمز بنجاح';

  @override
  String get passkeyRemovedSuccess => 'تم حذف إعدادات الأمان';

  @override
  String get faceId => 'التعرف على الوجه';

  @override
  String get fingerprint => 'بصمة الإصبع';

  @override
  String get biometrics => 'البيومترية';

  @override
  String get biometricEnabled => 'مفعّل';

  @override
  String get biometricDisabled => 'معطّل';

  @override
  String get biometricDescription =>
      'استخدم البيومترية للوصول السريع والآمن. يرجع للرمز في حالة الفشل.';

  @override
  String get biometricsNotAvailable => 'البيومترية غير متاحة على هذا الجهاز';

  @override
  String get confirmBiometric => 'تأكيد البيومترية للتفعيل';

  @override
  String get biometricAuthFailed => 'فشلت المصادقة البيومترية';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get securityStep1 => 'عند فتح التطبيق، سيُطلب منك التحقق من هويتك.';

  @override
  String get securityStep2 =>
      'أولاً، يتم محاولة التحقق البيومتري (التعرف على الوجه / البصمة) إذا كان مفعلاً.';

  @override
  String get securityStep3 =>
      'إذا فشلت البيومترية أو كانت معطلة، أدخل رمزك المكون من 6 أرقام.';

  @override
  String get securityStep4 =>
      'بعد 3 محاولات فاشلة، سيتم قفل حسابك مؤقتًا لحمايتك.';

  @override
  String get confirm => 'تأكيد';

  @override
  String get unlockApp => 'فتح التطبيق';

  @override
  String get enterPasskeyToUnlock => 'أدخل رمزك للفتح';

  @override
  String attemptsRemaining(int count) {
    return '$count محاولات متبقية';
  }

  @override
  String get accountLocked => 'الحساب مقفل';

  @override
  String accountLockedFor(String duration) {
    return 'الحساب مقفل لمدة $duration';
  }

  @override
  String get accountPermanentlyLocked =>
      'الحساب مقفل بشكل دائم. يرجى التواصل مع الدعم.';

  @override
  String tryAgainIn(String time) {
    return 'حاول مرة أخرى خلال $time';
  }

  @override
  String useBiometric(String type) {
    return 'استخدام $type';
  }

  @override
  String get usePasskeyInstead => 'استخدام الرمز بدلاً من ذلك';

  @override
  String get usePinInstead => 'استخدام رمز PIN بدلاً من ذلك';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get pinCode => 'رمز PIN';

  @override
  String get sixDigitPin => 'رمز PIN من 6 أرقام';

  @override
  String get setupPinCode => 'إعداد رمز PIN';

  @override
  String get setupPin => 'إعداد PIN';

  @override
  String get enterNewPin => 'أدخل رمز PIN مكون من 6 أرقام لتأمين حسابك';

  @override
  String get pinSetupSuccess => 'تم إعداد رمز PIN بنجاح';

  @override
  String get currentPin => 'رمز PIN الحالي';

  @override
  String get enterCurrentPin => 'أدخل رمز PIN الحالي';

  @override
  String get newPin => 'رمز PIN الجديد';

  @override
  String get changePin => 'تغيير';

  @override
  String get pinChangedSuccess => 'تم تغيير رمز PIN بنجاح';

  @override
  String get removePin => 'حذف رمز PIN';

  @override
  String get removePinConfirm =>
      'سيؤدي هذا إلى حذف رمز PIN الخاص بك. يمكنك إعداد رمز جديد في أي وقت.';

  @override
  String get verifyPin => 'التحقق من رمز PIN';

  @override
  String get enterPinToRemove => 'أدخل رمز PIN للتأكيد';

  @override
  String get pinRemovedSuccess => 'تم حذف رمز PIN';

  @override
  String get pinMustBe6Digits => 'يجب أن يكون رمز PIN مكون من 6 أرقام';

  @override
  String get incorrectPin => 'رمز PIN غير صحيح';

  @override
  String get confirmPin => 'تأكيد';

  @override
  String get pinsDoNotMatch => 'رموز PIN غير متطابقة';

  @override
  String get pinEnabled => 'مفعّل';

  @override
  String get pinNotSet => 'غير مُعد';

  @override
  String get pinEnabledDescription => 'حسابك محمي برمز PIN مكون من 6 أرقام.';

  @override
  String get pinDescription =>
      'قم بإعداد رمز PIN مكون من 6 أرقام كطريقة احتياطية لفتح التطبيق.';

  @override
  String get enterPinToUnlock => 'أدخل رمز PIN للفتح';

  @override
  String get devicePasskey => 'مفتاح المرور';

  @override
  String get passkeyShortDesc => 'تسجيل دخول بدون كلمة مرور';

  @override
  String get twoFactorAuth => 'المصادقة الثنائية';

  @override
  String get authenticatorApp => 'تطبيق المصادقة';

  @override
  String get twoFADescription =>
      'استخدم تطبيق مصادقة مثل Google Authenticator أو Authy لأمان إضافي.';

  @override
  String get twoFAShortDesc => 'Google Authenticator، Authy';

  @override
  String get setup2FA => 'إعداد المصادقة الثنائية';

  @override
  String get pinRequiredForFaceId => 'يرجى إعداد رمز PIN أولاً';

  @override
  String get requiresPinFirst => 'يتطلب رمز PIN';

  @override
  String get pinFirst => 'PIN أولاً';

  @override
  String get securityInfoShort =>
      'قم بإعداد رمز PIN أولاً، ثم فعّل التعرف على الوجه للفتح السريع. رمز PIN هو الاحتياطي.';

  @override
  String get failedToSetupPin => 'فشل إعداد رمز PIN';

  @override
  String get failedToChangePin => 'فشل تغيير رمز PIN';

  @override
  String get failedToRemovePin => 'فشل حذف رمز PIN';

  @override
  String get failedToUpdateBiometric => 'فشل تحديث إعدادات البيومترية';

  @override
  String get orDivider => 'أو';

  @override
  String get codeExpiresAfterUse => 'ينتهي الرمز بعد الاستخدام الأول';

  @override
  String get signInFailed => 'فشل تسجيل الدخول';

  @override
  String get signUpFailed => 'فشل إنشاء الحساب';

  @override
  String get signOutFailed => 'فشل تسجيل الخروج';

  @override
  String get googleSignInFailed => 'فشل تسجيل الدخول بجوجل';

  @override
  String get googleSignUpFailed => 'فشل إنشاء الحساب بجوجل';

  @override
  String get reenterPinToConfirm => 'أعد إدخال رمز PIN للتأكيد';

  @override
  String get continueText => 'متابعة';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get soon => 'قريباً';

  @override
  String get featureComingSoon => 'هذه الميزة قادمة قريباً!';

  @override
  String get useAnotherMethod => 'استخدم طريقة أخرى';

  @override
  String get unlockOptions => 'خيارات إلغاء القفل';

  @override
  String get chooseUnlockMethod => 'اختر طريقة إلغاء القفل';

  @override
  String get tryFaceIdAgain => 'حاول Face ID مرة أخرى';

  @override
  String get usePasskey => 'استخدم مفتاح المرور';

  @override
  String get use2FACode => 'استخدم رمز 2FA';

  @override
  String get enter2FACode => 'أدخل رمز 2FA';

  @override
  String get enter6DigitCode => 'أدخل الرمز المكون من 6 أرقام من تطبيقك';

  @override
  String get verifyCode => 'تحقق من الرمز';

  @override
  String get invalidCode => 'رمز غير صالح. حاول مرة أخرى.';

  @override
  String get twoFAEnabled => 'مفعّل';

  @override
  String get twoFADisabled => 'تم تعطيل المصادقة الثنائية';

  @override
  String get disable => 'تعطيل';

  @override
  String get disable2FA => 'تعطيل المصادقة الثنائية';

  @override
  String get pinRequiredFor2FA => 'يرجى إعداد رمز PIN أولاً';

  @override
  String get enterSixDigitCode => 'يرجى إدخال الرمز المكون من 6 أرقام';

  @override
  String get enterCodeToDisable2FA => 'أدخل الرمز من تطبيق المصادقة للتأكيد';

  @override
  String get twoFactorEnabled => 'تم تفعيل المصادقة الثنائية!';

  @override
  String get secretCopied => 'تم نسخ المفتاح السري';

  @override
  String get scanQrCode => 'امسح رمز QR هذا';

  @override
  String get useAuthenticatorApp =>
      'افتح تطبيق المصادقة وامسح رمز QR هذا لإضافة حسابك';

  @override
  String get orText => 'أو';

  @override
  String get enterManually => 'أدخل هذا المفتاح يدوياً';

  @override
  String get copySecretKey => 'نسخ المفتاح السري';

  @override
  String get authenticatorAccountInfo =>
      'سيكون اسم الحساب في تطبيق المصادقة هو عنوان بريدك الإلكتروني';

  @override
  String get enterVerificationCode => 'أدخل رمز التحقق';

  @override
  String get enterCodeFromAuthenticator =>
      'أدخل الرمز المكون من 6 أرقام من تطبيق المصادقة لإكمال الإعداد';

  @override
  String get codeRefreshesEvery30Seconds =>
      'تتجدد الرموز كل 30 ثانية. تأكد من إدخال الرمز الحالي.';

  @override
  String get activateTwoFactor => 'تفعيل المصادقة الثنائية';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get offlineMessage =>
      'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى. يجب أن تكون متصلاً لاستخدام هذا التطبيق.';

  @override
  String get connectionTip => 'نصيحة: حاول تفعيل الواي فاي أو بيانات الهاتف';

  @override
  String get closeApp => 'إغلاق التطبيق';

  @override
  String get retryHint => 'سيتصل التطبيق تلقائياً عند الاتصال بالإنترنت';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordDesc => 'تحديث كلمة مرور حسابك';

  @override
  String get changePasswordDialogDesc =>
      'أدخل كلمة المرور الحالية واختر كلمة مرور جديدة';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get currentPasswordRequired => 'كلمة المرور الحالية مطلوبة';

  @override
  String get passwordDoesNotMeetRequirements =>
      'كلمة المرور لا تستوفي المتطلبات';

  @override
  String get newPasswordMustBeDifferent =>
      'كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية';

  @override
  String get passwordChangedSuccess => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get failedToChangePassword => 'فشل في تغيير كلمة المرور';

  @override
  String get createPassword => 'إنشاء كلمة مرور';

  @override
  String get createPasswordDesc => 'أنشئ كلمة مرور لحسابك';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordCreatedSuccess => 'تم إنشاء كلمة المرور بنجاح';

  @override
  String get failedToCreatePassword => 'فشل في إنشاء كلمة المرور';

  @override
  String get alternativeUnlock => 'فتح بديل';

  @override
  String get chooseSecureMethod => 'اختر طريقة آمنة للفتح';

  @override
  String get authenticatorCode => 'رمز المصادقة';

  @override
  String get markAllRead => 'قراءة الكل';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get noNotificationsDesc => 'ستظهر التحديثات المهمة هنا';

  @override
  String get allNotificationsRead => 'تم تحديد جميع الإشعارات كمقروءة';

  @override
  String get completeProfile => 'أكمل الملف';

  @override
  String get setupSecurity => 'إعداد الأمان';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get notificationWelcomeTitle => 'مرحبًا بك في شقشقني';

  @override
  String get notificationWelcomeMessage =>
      'يسعدنا انضمامك إلى مجتمعنا! إذا كنت بحاجة إلى أي مساعدة، لا تتردد في التواصل مع فريق الدعم على support@cha9cha9ni.tn أو استخدم خيار المساعدة في القائمة.';

  @override
  String get notificationProfileTitle => 'أكمل ملفك الشخصي';

  @override
  String get notificationProfileMessage =>
      'لإجراء عمليات السحب والوصول إلى جميع ميزاتنا، يرجى إكمال معلوماتك الشخصية في إعدادات ملفك الشخصي. هذا يساعدنا على التحقق من هويتك والحفاظ على أمان حسابك.';

  @override
  String get notificationSecurityTitle => 'تأمين حسابك';

  @override
  String get notificationSecurityMessage =>
      'احمِ حسابك من خلال تفعيل المصادقة الثنائية (2FA) وإعداد رمز PIN. سيساعدك هذا على حماية بياناتك ومعاملاتك من أي وصول غير مصرح به.';

  @override
  String get read => 'مقروء';

  @override
  String get noRecentActivities => 'لا توجد أنشطة حديثة';

  @override
  String get wantsToRemoveYou => 'يريد إزالتك';

  @override
  String ownerRequestedRemoval(String ownerName) {
    return '$ownerName طلب إزالتك من العائلة';
  }

  @override
  String get respond => 'رد';

  @override
  String get signingYouIn => 'جاري تسجيل دخولك...';

  @override
  String get justNow => 'الآن';

  @override
  String minAgo(int count) {
    return 'منذ دقيقة';
  }

  @override
  String minsAgo(int count) {
    return 'منذ $count دقائق';
  }

  @override
  String hourAgo(int count) {
    return 'منذ ساعة';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعات';
  }

  @override
  String dayAgo(int count) {
    return 'منذ يوم';
  }

  @override
  String daysAgo(int count) {
    return 'منذ $count أيام';
  }

  @override
  String monthAgo(int count) {
    return 'منذ شهر';
  }

  @override
  String monthsAgo(int count) {
    return 'منذ $count أشهر';
  }

  @override
  String get loading => 'جار التحميل...';

  @override
  String get scanCode => 'استبدال بطاقة الهدايا';

  @override
  String get cameraPermissionRequired => 'إذن الكاميرا مطلوب';

  @override
  String get cameraPermissionDescription =>
      'نحتاج إلى الوصول إلى الكاميرا لمسح رموز بطاقات الهدايا ورموز QR.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get pointCameraAtCode => 'وجّه الكاميرا نحو رمز بطاقة الهدايا';

  @override
  String get enterCodeManually => 'أدخل الرمز يدوياً';

  @override
  String get scanInstead => 'مسح بدلاً من ذلك';

  @override
  String get enterCodeDescription =>
      'أدخل رمز بطاقة الهدايا لإضافة رصيد إلى حسابك';

  @override
  String get invalidCodeFormat => 'يرجى إدخال رمز استبدال صالح';

  @override
  String get codeScanned => 'تم مسح الرمز!';

  @override
  String get joinFamily => 'استبدال';

  @override
  String get rewardsPoints => 'نقاط';

  @override
  String get rewardsStreak => 'سلسلة';

  @override
  String get rewardsAds => 'إعلانات';

  @override
  String get rewardsDailyCheckIn => 'تسجيل الدخول اليومي';

  @override
  String rewardsDayStreak(int count) {
    return 'سلسلة $count يوم!';
  }

  @override
  String rewardsClaimPoints(int points) {
    return 'احصل على +$points نقطة';
  }

  @override
  String get rewardsClaimed => 'تم الحصول';

  @override
  String get rewardsNextIn => 'التالي في';

  @override
  String get rewardsWatchAndEarn => 'شاهد واكسب';

  @override
  String rewardsWatchAdToEarn(int points) {
    return 'شاهد إعلان لكسب +$points نقطة';
  }

  @override
  String get rewardsAllAdsWatched => 'شاهدت جميع الإعلانات اليوم!';

  @override
  String get rewardsRedeemRewards => 'استبدال المكافآت';

  @override
  String get rewardsConvertPoints => 'تحويل النقاط إلى دينار';

  @override
  String get rewardsRedeem => 'استبدال';

  @override
  String get rewardsComingSoon => 'قريباً!';

  @override
  String rewardsRedeemingFor(String name, String points) {
    return 'استبدال $name مقابل $points نقطة سيكون متاحاً قريباً!';
  }

  @override
  String get rewardsGotIt => 'فهمت!';

  @override
  String get rewardsSimulatedAd => 'إعلان تجريبي';

  @override
  String get rewardsSimulatedAdDesc =>
      'في الإنتاج، سيتم عرض إعلان حقيقي مع مكافأة هنا.';

  @override
  String get rewardsSkipAd => 'تخطي الإعلان';

  @override
  String get rewardsWatchComplete => 'اكتمل المشاهدة';

  @override
  String get rewardsPointsEarned => 'تم كسب النقاط!';

  @override
  String get rewardsAdReward => 'مكافأة الإعلان';

  @override
  String get rewardsDailyReward => 'المكافأة اليومية';

  @override
  String get rewardsLoadingAd => 'جاري تحميل الإعلان...';

  @override
  String get rewardsCheckInSuccess => 'تم تسجيل الدخول بنجاح!';

  @override
  String get rewardsCheckInFailed =>
      'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get rewardsClaimFailed =>
      'فشل في الحصول على المكافأة. يرجى المحاولة مرة أخرى.';

  @override
  String get rewardsAdFailed => 'فشل في عرض الإعلان. يرجى المحاولة مرة أخرى.';

  @override
  String get allActivities => 'جميع الأنشطة';

  @override
  String get activitiesWillAppearHere =>
      'ستظهر أنشطة العائلة هنا عندما يكسب الأعضاء نقاط';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String activityWatchedAd(String name) {
    return '$name شاهد إعلان';
  }

  @override
  String activityDailyCheckIn(String name) {
    return '$name حصل على مكافأة الدخول اليومي';
  }

  @override
  String activityTopUp(String name) {
    return '$name قام بالشحن';
  }

  @override
  String activityReferral(String name) {
    return 'مكافأة إحالة $name';
  }

  @override
  String activityEarnedPoints(String name) {
    return '$name كسب نقاط';
  }

  @override
  String get filterActivities => 'تصفية الأنشطة';

  @override
  String get filterByTime => 'حسب الفترة الزمنية';

  @override
  String get filterByType => 'حسب نوع النشاط';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterLast7Days => 'آخر 7 أيام';

  @override
  String get filterLast30Days => 'آخر 30 يوم';

  @override
  String get filterLast3Months => 'آخر 3 أشهر';

  @override
  String get filterAllTypes => 'جميع الأنواع';

  @override
  String get filterAds => 'الإعلانات';

  @override
  String get filterCheckIn => 'تسجيل الدخول اليومي';

  @override
  String get filterTopUp => 'الشحن';

  @override
  String get filterReferral => 'الإحالة';

  @override
  String get filterOther => 'أخرى';

  @override
  String get applyFilters => 'تطبيق الفلاتر';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get noActivitiesForFilter => 'لا توجد أنشطة تطابق الفلاتر المحددة';

  @override
  String get usageAndLimits => 'الاستخدام والحدود';

  @override
  String ownerPlusMembers(int count) {
    return 'المالك + $count أعضاء';
  }

  @override
  String get withdrawAccess => 'صلاحية السحب';

  @override
  String get ownerOnlyCanWithdraw => 'المالك فقط يمكنه السحب';

  @override
  String get youAreOwner => 'أنت مالك العائلة';

  @override
  String get onlyOwnerCanWithdrawDescription =>
      'فقط مالك العائلة يمكنه سحب الأموال';

  @override
  String get kycVerified => 'تم التحقق من الهوية';

  @override
  String get kycRequired => 'مطلوب التحقق من الهوية للسحب';

  @override
  String get verifyIdentity => 'التحقق من الهوية';

  @override
  String get selectedAid => 'العيد المختار';

  @override
  String get selectAnAid => 'اضغط لاختيار عيد';

  @override
  String maxDT(int amount) {
    return 'الحد الأقصى $amount دينار';
  }

  @override
  String get adsToday => 'إعلانات اليوم';

  @override
  String adsPerMember(int count) {
    return '$count إعلانات / عضو';
  }

  @override
  String get watched => 'تمت المشاهدة';

  @override
  String get adsDescription => 'شاهد الإعلانات لكسب نقاط لمدخرات عائلتك';

  @override
  String get unlockMoreBenefits =>
      'قم بترقية باقتك للحصول على المزيد من المزايا والسحوبات والأعياد';

  @override
  String get changeMyPack => 'تغيير باقتي';

  @override
  String get free => 'مجاني';

  @override
  String get month => 'شهر';

  @override
  String get year => 'سنة';

  @override
  String get monthly => 'شهري';

  @override
  String get yearly => 'سنوي';

  @override
  String upToAmount(int amount) {
    return 'حتى $amount دينار إجمالي';
  }

  @override
  String withdrawalsPerYear(int count) {
    return '$count سحوبات / سنة';
  }

  @override
  String get allPacks => 'جميع الباقات';

  @override
  String get choosePack => 'اختر باقتك';

  @override
  String get choosePackDescription => 'اختر الباقة التي تناسب احتياجات عائلتك';

  @override
  String minimumWithdrawal(int amount) {
    return 'الحد الأدنى للسحب هو $amount دينار';
  }

  @override
  String familyMembersCount(int count) {
    return '$count أفراد العائلة';
  }

  @override
  String aidsSelectable(int count) {
    return '$count أعياد قابلة للاختيار';
  }

  @override
  String get currentPack => 'الباقة الحالية';

  @override
  String get selectPack => 'اختيار الباقة';

  @override
  String upgradeTo(String name) {
    return 'الترقية إلى $name';
  }

  @override
  String downgradeTo(String name) {
    return 'التخفيض إلى $name';
  }

  @override
  String get downgradeConfirmation =>
      'هل أنت متأكد من أنك تريد التبديل إلى الباقة المجانية؟ قد تفقد الوصول إلى بعض الميزات.';

  @override
  String upgradeConfirmation(String name, int price) {
    return 'الترقية إلى $name مقابل $price دينار/شهر؟';
  }

  @override
  String get confirmSelection => 'تأكيد الاختيار';

  @override
  String get subscriptionComingSoon => 'إدارة الاشتراكات قريباً!';

  @override
  String get selectAid => 'اختيار العيد';

  @override
  String get tunisianAids => 'الأعياد التونسية';

  @override
  String selectionsRemaining(int remaining, int total) {
    return '$remaining من $total اختيارات متاحة';
  }

  @override
  String get aidSelectionDescription =>
      'اختر عيدك المفضل للسحب. كل عيد له فترات سحب ومبالغ قصوى محددة.';

  @override
  String get aidSelectionHint =>
      'المبلغ المعروض هو الحد الأقصى الذي يمكنك سحبه خلال فترة هذا العيد بعد اختياره.';

  @override
  String get packBasedWithdrawalHint =>
      'قم بترقية باقتك لفتح حدود سحب أعلى واختيار المزيد من الأعياد!';

  @override
  String get withdrawalLimit => 'يمكنك سحب حتى';

  @override
  String get limitReached => 'تم الوصول للحد';

  @override
  String get yourSelectedAids => 'أعيادك المختارة';

  @override
  String get availableAids => 'الأعياد المتاحة';

  @override
  String get selected => 'مختار';

  @override
  String get maxWithdrawal => 'الحد الأقصى للسحب';

  @override
  String get window => 'الفترة';

  @override
  String get select => 'اختيار';

  @override
  String get aidAlreadySelected => 'هذا العيد مختار بالفعل';

  @override
  String maxAidsReached(int count) {
    return 'يمكنك اختيار $count عيد(أعياد) فقط مع باقتك الحالية';
  }

  @override
  String get selectAidConfirmTitle => 'تأكيد اختيار العيد';

  @override
  String selectAidConfirmMessage(String name) {
    return 'هل أنت متأكد من أنك تريد اختيار $name؟';
  }

  @override
  String get aidSelectionWarning =>
      'لا يمكنك تغيير عيدك المختار دون الاتصال بالدعم';

  @override
  String aidSelectedSuccess(String name) {
    return 'تم اختيار $name بنجاح';
  }

  @override
  String get viewOnlyPackInfo => 'فقط مالك العائلة يمكنه إدارة الباقة والأعياد';

  @override
  String get noAidSelected => 'لم يتم اختيار عيد بعد';

  @override
  String daysUntilAid(int days, String aidName) {
    return '$days يوم حتى $aidName';
  }

  @override
  String get aidWindowOpen => 'نافذة السحب مفتوحة!';

  @override
  String aidWindowClosed(int days) {
    return 'النافذة تفتح بعد $days أيام';
  }

  @override
  String get leaveFamilyTitle => 'مغادرة العائلة';

  @override
  String get leaveFamilyConfirmMessage =>
      'هل أنت متأكد من مغادرة هذه العائلة؟ نقاطك ستبقى مع عائلتك الحالية وستبدأ من جديد إذا انضممت لعائلة أخرى.';

  @override
  String get leaveFamilyWarning => 'لا يمكن التراجع عن هذا الإجراء';

  @override
  String get leave => 'مغادرة';

  @override
  String get leaveFamilyCodeSent => 'تم إرسال رمز التأكيد إلى بريدك الإلكتروني';

  @override
  String get leaveFamilySuccess => 'لقد غادرت العائلة بنجاح';

  @override
  String get leaveFamilyConfirmTitle => 'تأكيد المغادرة';

  @override
  String get leaveFamilyCodePrompt =>
      'أدخل الرمز المكون من 6 أرقام المرسل إلى بريدك الإلكتروني لتأكيد المغادرة';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get resendCodeIn => 'إعادة الإرسال خلال';

  @override
  String get codeSentAgain => 'تم إرسال الرمز مجدداً';

  @override
  String tooManyAttempts(Object minutes) {
    return 'محاولات كثيرة جداً. يرجى المحاولة مرة أخرى بعد $minutes دقيقة.';
  }

  @override
  String get tooManyAttemptsTitle => 'محاولات كثيرة جداً';
}
