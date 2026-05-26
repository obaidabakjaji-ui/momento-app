// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Huddlex';

  @override
  String get appTagline => 'كل لمّة، تُشارك بأناقة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonRemove => 'إزالة';

  @override
  String get commonCopy => 'نسخ';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonSubmit => 'إرسال';

  @override
  String get commonSomethingWentWrong => 'حدث خطأ ما';

  @override
  String commonFailedWithError(String error) {
    return 'فشل: $error';
  }

  @override
  String get commonYouAreOffline => 'أنت غير متصل بالإنترنت';

  @override
  String get authYourName => 'اسمك';

  @override
  String get authYourNameHint => 'أدخل اسمك';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authEmailHint => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authPasswordHint => '6 أحرف على الأقل';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authForgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get authContinueWithGoogle => 'المتابعة عبر Google';

  @override
  String get authAlreadyHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get authNoAccount => 'ليس لديك حساب؟ سجّل الآن';

  @override
  String get authByCreatingYouAgree => 'بإنشائك حسابًا، فإنك توافق على ';

  @override
  String get authBySigningInYouAgree => 'بتسجيل دخولك، فإنك توافق على ';

  @override
  String get authTerms => 'الشروط';

  @override
  String get authPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get authResetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get authResetPasswordDescription =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.';

  @override
  String get authSend => 'إرسال';

  @override
  String authResetLinkSent(String email) {
    return 'تم إرسال رابط إعادة التعيين إلى $email';
  }

  @override
  String get verifyTitle => 'افحص بريدك الإلكتروني';

  @override
  String verifyDescription(String email) {
    return 'أرسلنا رمزًا من 6 أرقام إلى $email. أدخله أدناه لتأكيد حسابك.';
  }

  @override
  String get verifyCodeSent => 'تم إرسال الرمز — افحص بريدك الوارد.';

  @override
  String get verifyCodeSentNew => 'تم إرسال رمز جديد — افحص بريدك الوارد.';

  @override
  String get verifyCodeFailed =>
      'تعذر إرسال الرمز. اضغط على إعادة الإرسال للمحاولة مرة أخرى.';

  @override
  String get verifyCodeFailedNew => 'تعذر إرسال رمز جديد. حاول مرة أخرى.';

  @override
  String get verifySomethingWrong => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String verifyResendIn(int seconds) {
    return 'إعادة إرسال الرمز خلال $seconds ث';
  }

  @override
  String get verifyResend => 'إعادة إرسال الرمز';

  @override
  String get onboardingWelcomeTitle => 'مرحبًا بك في Huddlex';

  @override
  String get onboardingWelcomeBody =>
      'شارك لحظاتك العفوية مع أقرب الناس إليك. لا أعداد إعجابات، ولا خوارزميات — فقط لمحات صغيرة من يومك.';

  @override
  String get onboardingRoomsTitle => 'أنشئ مجتمعات أو انضم إليها';

  @override
  String get onboardingRoomsBody =>
      'المجتمع هو مساحة خاصة لمشاركة الصور. أنشئ واحدًا لعائلتك، رحلتك، أو مجموعة أصدقائك — وادعُ الناس برمز من 6 أحرف.';

  @override
  String get onboardingExpireTitle => 'تختفي الصور خلال 6 ساعات';

  @override
  String get onboardingExpireBody =>
      'كل صورة تنتهي صلاحيتها تلقائيًا. التقط، شارك، وامضِ — لا أرشيف، ولا ضغط.';

  @override
  String get onboardingSkip => 'تخطّي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingGetStarted => 'ابدأ';

  @override
  String get homeFeed => 'الموجز';

  @override
  String get homeRooms => 'المجتمعات';

  @override
  String get homeAccount => 'الحساب';

  @override
  String get homeNewMomento => 'لمّة جديدة';

  @override
  String get homeCouldNotLoadAccount => 'تعذر تحميل حسابك.';

  @override
  String get homeCouldNotLoadRooms => 'تعذر تحميل مجتمعاتك.';

  @override
  String get homeCouldNotLoadPosts => 'تعذر تحميل المنشورات.';

  @override
  String get homeNoRoomsTitle => 'لا توجد مجتمعات بعد';

  @override
  String get homeNoRoomsHomeBody =>
      'افتح علامة المجتمعات لإنشاء أو الانضمام إلى واحد.';

  @override
  String get homeNoMomentosTitle => 'لا توجد لمّات بعد';

  @override
  String get homeNoMomentosBody => 'التقط صورة وشاركها مع مجتمعاتك!';

  @override
  String get homeExpired => 'منتهي';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return 'متبقي $hours س $minutes د';
  }

  @override
  String get roomsMyRooms => 'مجتمعاتي';

  @override
  String get roomsJoinByCode => 'الانضمام برمز';

  @override
  String get roomsCreateRoom => 'إنشاء مجتمع';

  @override
  String get roomsJoinRoom => 'الانضمام إلى مجتمع';

  @override
  String get roomsEmptyTitle => 'لا توجد مجتمعات بعد';

  @override
  String get roomsEmptyBody =>
      'أنشئ مجتمعًا جديدًا أو انضم إلى واحد برمز لتبدأ مشاركة لمّاتك.';

  @override
  String get roomsCodePrefix => 'الرمز ';

  @override
  String get roomsFavorite => 'إضافة للمفضلة';

  @override
  String get roomsUnfavorite => 'إزالة من المفضلة';

  @override
  String get roomsActivate => 'تفعيل';

  @override
  String get roomsDeactivate => 'إلغاء التفعيل';

  @override
  String get createRoomTitle => 'إنشاء مجتمع';

  @override
  String get createRoomPhotoLabel => 'صورة المجتمع (اختياري)';

  @override
  String get createRoomNameLabel => 'اسم المجتمع';

  @override
  String get createRoomNameHint => 'مثال: العائلة، رحلة 2026، أعز الأصدقاء';

  @override
  String get createRoomNameRequired => 'يرجى إدخال اسم المجتمع';

  @override
  String get createRoomWhoCanJoin => 'من يمكنه الانضمام؟';

  @override
  String get createRoomPublic => 'عام';

  @override
  String get createRoomPublicDescription =>
      'يمكن لأي شخص لديه رمز المجتمع الانضمام فورًا';

  @override
  String get createRoomPermission => 'بإذن';

  @override
  String get createRoomPermissionDescription =>
      'يجب أن يوافق المشرف على الأعضاء الجدد';

  @override
  String get joinRoomTitle => 'الانضمام إلى مجتمع';

  @override
  String get joinRoomHaveCode => 'هل لديك رمز؟';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix => 'رموز المجتمعات مكونة من 6 أحرف';

  @override
  String get joinRoomNotFound => 'لا يوجد مجتمع بهذا الرمز';

  @override
  String joinRoomRequestSent(String name) {
    return 'تم إرسال الطلب. بانتظار موافقة مشرف \"$name\".';
  }

  @override
  String get joinRoomSearch => 'أو ابحث في المجتمعات العامة';

  @override
  String get joinRoomSearchHint => 'اسم المجتمع…';

  @override
  String get joinRoomNoResults => 'لا توجد مجتمعات عامة مطابقة.';

  @override
  String get joinRoomPermissionOnly =>
      'المجتمعات بإذن لا يمكن الانضمام إليها إلا برمزها.';

  @override
  String joinRoomMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      many: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: 'لا يوجد أعضاء',
    );
    return '$_temp0';
  }

  @override
  String get joinRoomJoin => 'انضمام';

  @override
  String get roomDetailSettings => 'إعدادات المجتمع';

  @override
  String get roomDetailMembers => 'الأعضاء';

  @override
  String get roomDetailCouldNotLoadPosts => 'تعذر تحميل المنشورات.';

  @override
  String get roomDetailEmptyTitle => 'لا توجد لمّات في هذا المجتمع بعد';

  @override
  String get roomDetailEmptyBody =>
      'التقط صورة من الكاميرا لتكون أول من يشارك.';

  @override
  String get roomSettingsTitle => 'إعدادات المجتمع';

  @override
  String get roomSettingsRename => 'إعادة تسمية المجتمع';

  @override
  String get roomSettingsModeration => 'الإشراف';

  @override
  String get roomSettingsPendingJoinRequests => 'طلبات الانضمام المعلقة';

  @override
  String roomSettingsMembersCount(int count) {
    return 'الأعضاء ($count)';
  }

  @override
  String get roomSettingsLeaveRoom => 'مغادرة المجتمع';

  @override
  String get roomSettingsDeleteRoom => 'حذف المجتمع';

  @override
  String get roomSettingsPublic => 'عام';

  @override
  String get roomSettingsPermission => 'بإذن';

  @override
  String get roomSettingsRoomCode => 'رمز المجتمع';

  @override
  String get roomSettingsCodeCopied => 'تم نسخ الرمز!';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return 'انضم إلى مجتمع \"$name\" على Huddlex — استخدم الرمز $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return 'انضم إلى $name على Huddlex';
  }

  @override
  String get roomSettingsRequirePostApproval => 'اشتراط موافقة على المنشورات';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      'تنتظر منشورات الأعضاء العاديين موافقة المشرف. أما المشرفون والمستخدمون الموثوقون فينشرون فورًا.';

  @override
  String get roomSettingsReviewPending => 'مراجعة المنشورات المعلقة';

  @override
  String get roomSettingsNoPending => 'لا توجد طلبات معلقة';

  @override
  String get roomSettingsTrustedTag => 'موثوق — يتجاوز موافقة المنشورات';

  @override
  String get roomSettingsMakeAdmin => 'تعيين كمشرف';

  @override
  String get roomSettingsRemoveAdmin => 'إزالة المشرف';

  @override
  String get roomSettingsRemoveTrusted => 'إزالة حالة الموثوق';

  @override
  String get roomSettingsMarkTrusted => 'تعيين كموثوق';

  @override
  String get roomSettingsRemoveFromRoom => 'إزالة من المجتمع';

  @override
  String get roomSettingsRemoveMemberTitle => 'إزالة العضو؟';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return 'ستتم إزالة $member من \"$room\".';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return 'فشل تحديث الصورة: $error';
  }

  @override
  String get roomSettingsNewName => 'الاسم الجديد';

  @override
  String get roomSettingsLeaveTitle => 'مغادرة المجتمع؟';

  @override
  String roomSettingsLeaveBody(String name) {
    return 'ستتوقف عن استلام لمّات من \"$name\".';
  }

  @override
  String get roomSettingsLeave => 'مغادرة';

  @override
  String get roomSettingsDeleteTitle => 'حذف المجتمع؟';

  @override
  String roomSettingsDeleteBody(String name) {
    return 'سيتم حذف \"$name\" نهائيًا لجميع الأعضاء. لا يمكن التراجع.';
  }

  @override
  String pendingPostsTitle(String room) {
    return 'المعلقة — $room';
  }

  @override
  String get pendingPostsEmpty => 'لا شيء بانتظار الموافقة.';

  @override
  String get pendingPostsReject => 'رفض';

  @override
  String get pendingPostsApprove => 'موافقة';

  @override
  String get cameraTitle => 'لمّة جديدة';

  @override
  String get cameraNoRooms =>
      'انضم إلى مجتمع أو أنشئ واحدًا أولًا لنشر اللمّات.';

  @override
  String get cameraProcessingVideo => 'معالجة الفيديو…';

  @override
  String get cameraMuted => 'كتم';

  @override
  String get cameraCaptureHint => 'التقط صورة أو مقطعًا مدته 6 ثوان';

  @override
  String get cameraPhoto => 'صورة';

  @override
  String get cameraVideo => 'فيديو';

  @override
  String get cameraPhotoFromGallery => 'صورة من المعرض';

  @override
  String get cameraVideoFromGallery => 'فيديو من المعرض';

  @override
  String get cameraRetake => 'إعادة الالتقاط';

  @override
  String get cameraPostClip => 'نشر المقطع';

  @override
  String get cameraPostMomento => 'نشر اللمّة';

  @override
  String get cameraCaptionHint => 'أضف تعليقًا (اختياري)';

  @override
  String get cameraPostTo => 'نشر إلى';

  @override
  String cameraActiveRoomsCount(int count) {
    return 'المجتمعات النشطة ($count)';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return 'كل المجتمعات ($count)';
  }

  @override
  String get cameraPickRooms => 'اختر…';

  @override
  String get cameraPickAtLeastOne => 'اختر مجتمعًا واحدًا على الأقل';

  @override
  String cameraPostedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم النشر إلى $count مجتمع!',
      many: 'تم النشر إلى $count مجتمعًا!',
      few: 'تم النشر إلى $count مجتمعات!',
      two: 'تم النشر إلى مجتمعين!',
      one: 'تم النشر إلى مجتمع واحد!',
      zero: 'لم تُنشر بعد',
    );
    return '$_temp0';
  }

  @override
  String cameraPendingApproval(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منشور بانتظار موافقة المشرف.',
      many: '$count منشورًا بانتظار موافقة المشرف.',
      few: '$count منشورات بانتظار موافقة المشرف.',
      two: 'منشوران بانتظار موافقة المشرف.',
      one: 'منشور واحد بانتظار موافقة المشرف.',
      zero: 'لا منشورات معلقة',
    );
    return '$_temp0';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live منشور، $pending بانتظار موافقة المشرف.';
  }

  @override
  String cameraFailedToSend(String error) {
    return 'فشل الإرسال: $error';
  }

  @override
  String get cameraCouldNotProcessVideo => 'تعذر معالجة الفيديو.';

  @override
  String get cameraVideoTooLong => 'يجب ألا يزيد الفيديو عن 6 ثوان.';

  @override
  String get cameraCouldNotPoster => 'تعذر إنشاء صورة الغلاف.';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get accountActiveRooms => 'المجتمعات النشطة';

  @override
  String get accountActiveRoomsDescription =>
      'تذهب المنشورات إلى هنا تلقائيًا. تحكم بالتفعيل من علامة المجتمعات.';

  @override
  String get accountFavoriteRooms => 'المجتمعات المفضلة';

  @override
  String get accountFavoriteRoomsDescription =>
      'تظهر المفضلة أولًا في الموجز ودوران الويدجت.';

  @override
  String get accountBlockedUsers => 'المستخدمون المحظورون';

  @override
  String get accountLegal => 'قانوني';

  @override
  String get accountTermsOfService => 'شروط الخدمة';

  @override
  String get accountPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountDeleteMy => 'حذف حسابي';

  @override
  String get accountDeleteTitle => 'حذف حسابك؟';

  @override
  String get accountDeleteBody =>
      'سيتم حذف حسابك وعضوياتك في كل المجتمعات ومفضلاتك نهائيًا. ستنتهي صلاحية المنشورات تلقائيًا. لا يمكن التراجع.';

  @override
  String get accountReauthRequired =>
      'يرجى تسجيل الخروج وإعادة الدخول، ثم حاول الحذف مرة أخرى.';

  @override
  String accountFailedWithMessage(String message) {
    return 'فشل: $message';
  }

  @override
  String accountRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مجتمع',
      many: '$count مجتمعًا',
      few: '$count مجتمعات',
      two: 'مجتمعان',
      one: 'مجتمع واحد',
      zero: 'لا مجتمعات',
    );
    return '$_temp0';
  }

  @override
  String get accountEditProfile => 'تحرير الملف الشخصي';

  @override
  String accountStreakDays(int count) {
    return 'سلسلة $count يومًا';
  }

  @override
  String accountStreakBest(int count) {
    return 'الأفضل: $count يومًا';
  }

  @override
  String get accountStreakKeepGoing => 'استمر — انشر اليوم';

  @override
  String get accountNoBlocked => 'لا يوجد مستخدمون محظورون';

  @override
  String get accountUnblock => 'إلغاء الحظر';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get accountLanguageSystem => 'افتراضي النظام';

  @override
  String get accountNoActiveRooms => 'لا توجد مجتمعات نشطة';

  @override
  String get accountNoFavorites => 'لا توجد مفضلات';

  @override
  String get roomSettingsCreator => 'المُنشئ';

  @override
  String get roomSettingsAdmin => 'مشرف';

  @override
  String get editProfileTitle => 'تحرير الملف الشخصي';

  @override
  String get editProfileTapPhoto => 'اضغط لتغيير الصورة';

  @override
  String get editProfileDisplayName => 'الاسم المعروض';

  @override
  String get editProfileNameRequired => 'لا يمكن أن يكون الاسم فارغًا';

  @override
  String editProfileFailedSave(String error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String get postActionsReportTitle => 'الإبلاغ عن المنشور';

  @override
  String get postActionsReportPrompt => 'لماذا تبلغ عن هذا المنشور؟';

  @override
  String get postActionsReportPlaceholder => 'اختياري — صف ما هو الخطأ';

  @override
  String get postActionsReportSubmitted => 'تم إرسال البلاغ. شكرًا.';

  @override
  String postActionsBlockUser(String name) {
    return 'حظر $name';
  }

  @override
  String get postActionsBlockDescription => 'لن ترى منشوراته في أي مجتمع';

  @override
  String postActionsUserBlocked(String name) {
    return 'تم حظر $name.';
  }

  @override
  String get postActionsOwnPost => 'هذا منشورك أنت';

  @override
  String get postActionsNoActions => 'لا تتوفر إجراءات إشراف';

  @override
  String postActionsBlockTitle(String name) {
    return 'حظر $name؟';
  }

  @override
  String postActionsBlockBody(String name) {
    return 'لن ترى منشورات $name في أي مجتمع. لن يتم إعلامه.';
  }

  @override
  String get postActionsBlock => 'حظر';

  @override
  String likedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أعجب $count شخص',
      many: 'أعجب $count شخصًا',
      few: 'أعجب $count أشخاص',
      two: 'أعجب شخصان',
      one: 'أعجب شخص واحد',
      zero: 'لم يُعجب أحد',
    );
    return '$_temp0';
  }
}
