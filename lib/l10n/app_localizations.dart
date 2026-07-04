import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Huddlex'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Every huddle, shared beautifully'**
  String get appTagline;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String commonFailedWithError(String error);

  /// No description provided for @commonYouAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get commonYouAreOffline;

  /// No description provided for @authYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authYourName;

  /// No description provided for @authYourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authYourNameHint;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailHint;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailPlaceholder;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get authPasswordHint;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authNoAccount;

  /// No description provided for @authByCreatingYouAgree.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to our '**
  String get authByCreatingYouAgree;

  /// No description provided for @authBySigningInYouAgree.
  ///
  /// In en, this message translates to:
  /// **'By signing in you agree to our '**
  String get authBySigningInYouAgree;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get authTerms;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get authResetPasswordDescription;

  /// No description provided for @authSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get authSend;

  /// No description provided for @authResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}'**
  String authResetLinkSent(String email);

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get verifyTitle;

  /// No description provided for @verifyDescription.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. Enter it below to confirm your account.'**
  String verifyDescription(String email);

  /// No description provided for @verifyCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent — check your inbox.'**
  String get verifyCodeSent;

  /// No description provided for @verifyCodeSentNew.
  ///
  /// In en, this message translates to:
  /// **'New code sent — check your inbox.'**
  String get verifyCodeSentNew;

  /// No description provided for @verifyCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send a code. Tap resend to try again.'**
  String get verifyCodeFailed;

  /// No description provided for @verifyCodeFailedNew.
  ///
  /// In en, this message translates to:
  /// **'Could not send a new code. Try again.'**
  String get verifyCodeFailedNew;

  /// No description provided for @verifySomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get verifySomethingWrong;

  /// No description provided for @verifyResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String verifyResendIn(int seconds);

  /// No description provided for @verifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyResend;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Huddlex'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Share unfiltered moments with the people closest to you. No likes counts, no algorithms — just little glimpses of your day.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Create or join Communities'**
  String get onboardingRoomsTitle;

  /// No description provided for @onboardingRoomsBody.
  ///
  /// In en, this message translates to:
  /// **'A Community is a private space for sharing photos. Start one for your family, your trip, your group of friends — and invite people with a 6-character code.'**
  String get onboardingRoomsBody;

  /// No description provided for @onboardingExpireTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos disappear in 6 hours'**
  String get onboardingExpireTitle;

  /// No description provided for @onboardingExpireBody.
  ///
  /// In en, this message translates to:
  /// **'Every photo expires automatically. Snap, share, and move on — no archive, no pressure.'**
  String get onboardingExpireBody;

  /// No description provided for @onboardingWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'On your home screen'**
  String get onboardingWidgetTitle;

  /// No description provided for @onboardingWidgetBody.
  ///
  /// In en, this message translates to:
  /// **'Drop the Huddlex widget on your home screen and your latest huddles cycle through it all day.'**
  String get onboardingWidgetBody;

  /// No description provided for @onboardingLocationLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin a place (optional)'**
  String get onboardingLocationLockTitle;

  /// No description provided for @onboardingLocationLockBody.
  ///
  /// In en, this message translates to:
  /// **'Community admins can lock posting to a real-world spot — a class, an event, a hangout. Posts from outside the area need approval first.'**
  String get onboardingLocationLockBody;

  /// No description provided for @roomSettingsReportRoom.
  ///
  /// In en, this message translates to:
  /// **'Report this community'**
  String get roomSettingsReportRoom;

  /// No description provided for @roomSettingsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this community?'**
  String get roomSettingsReportTitle;

  /// No description provided for @roomSettingsReportBody.
  ///
  /// In en, this message translates to:
  /// **'Our team will review this community. You can keep using it while we look — leave it from here if you\'d rather not see it again.'**
  String get roomSettingsReportBody;

  /// No description provided for @roomSettingsReportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong here? (optional)'**
  String get roomSettingsReportReasonHint;

  /// No description provided for @roomSettingsReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get roomSettingsReportSubmit;

  /// No description provided for @roomSettingsReportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks — we\'ll take a look.'**
  String get roomSettingsReportSent;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @homeFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get homeFeed;

  /// No description provided for @homeRooms.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get homeRooms;

  /// No description provided for @homeAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get homeAccount;

  /// No description provided for @homeNewMomento.
  ///
  /// In en, this message translates to:
  /// **'New Huddle'**
  String get homeNewMomento;

  /// No description provided for @homeCouldNotLoadAccount.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your account.'**
  String get homeCouldNotLoadAccount;

  /// No description provided for @homeCouldNotLoadRooms.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your communities.'**
  String get homeCouldNotLoadRooms;

  /// No description provided for @homeCouldNotLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load posts.'**
  String get homeCouldNotLoadPosts;

  /// No description provided for @homeNoRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'No communities yet'**
  String get homeNoRoomsTitle;

  /// No description provided for @homeNoRoomsHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Open the Communities tab to create or join one.'**
  String get homeNoRoomsHomeBody;

  /// No description provided for @homeNoMomentosTitle.
  ///
  /// In en, this message translates to:
  /// **'No huddles yet'**
  String get homeNoMomentosTitle;

  /// No description provided for @homeNoMomentosBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo and share it with your communities!'**
  String get homeNoMomentosBody;

  /// No description provided for @homeExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get homeExpired;

  /// No description provided for @homeTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m remaining'**
  String homeTimeRemaining(int hours, int minutes);

  /// No description provided for @roomsMyRooms.
  ///
  /// In en, this message translates to:
  /// **'My Communities'**
  String get roomsMyRooms;

  /// No description provided for @roomsJoinByCode.
  ///
  /// In en, this message translates to:
  /// **'Join by code'**
  String get roomsJoinByCode;

  /// No description provided for @roomsCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get roomsCreateRoom;

  /// No description provided for @roomsJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get roomsJoinRoom;

  /// No description provided for @roomsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No communities yet'**
  String get roomsEmptyTitle;

  /// No description provided for @roomsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a new community or join one with a code to start sharing huddles.'**
  String get roomsEmptyBody;

  /// No description provided for @roomsCodePrefix.
  ///
  /// In en, this message translates to:
  /// **'Code '**
  String get roomsCodePrefix;

  /// No description provided for @roomsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get roomsFavorite;

  /// No description provided for @roomsUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get roomsUnfavorite;

  /// No description provided for @roomsActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get roomsActivate;

  /// No description provided for @roomsDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get roomsDeactivate;

  /// No description provided for @createRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get createRoomTitle;

  /// No description provided for @createRoomPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Community photo (optional)'**
  String get createRoomPhotoLabel;

  /// No description provided for @createRoomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Community name'**
  String get createRoomNameLabel;

  /// No description provided for @createRoomNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Family, Trip 2026, Best Friends'**
  String get createRoomNameHint;

  /// No description provided for @createRoomNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a community name'**
  String get createRoomNameRequired;

  /// No description provided for @createRoomWhoCanJoin.
  ///
  /// In en, this message translates to:
  /// **'Who can join?'**
  String get createRoomWhoCanJoin;

  /// No description provided for @createRoomPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get createRoomPublic;

  /// No description provided for @createRoomPublicDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the community code can join instantly'**
  String get createRoomPublicDescription;

  /// No description provided for @createRoomPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get createRoomPermission;

  /// No description provided for @createRoomPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'New members must be approved by an admin'**
  String get createRoomPermissionDescription;

  /// No description provided for @joinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get joinRoomTitle;

  /// No description provided for @joinRoomHaveCode.
  ///
  /// In en, this message translates to:
  /// **'Have a code?'**
  String get joinRoomHaveCode;

  /// No description provided for @joinRoomCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'A7BX92'**
  String get joinRoomCodePlaceholder;

  /// No description provided for @joinRoomCodeMustBeSix.
  ///
  /// In en, this message translates to:
  /// **'Community codes are 6 characters'**
  String get joinRoomCodeMustBeSix;

  /// No description provided for @joinRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'No community found with that code'**
  String get joinRoomNotFound;

  /// No description provided for @joinRoomRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent. Waiting for an admin of \"{name}\" to approve.'**
  String joinRoomRequestSent(String name);

  /// No description provided for @joinRoomSearch.
  ///
  /// In en, this message translates to:
  /// **'Or search public communities'**
  String get joinRoomSearch;

  /// No description provided for @joinRoomSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Community name…'**
  String get joinRoomSearchHint;

  /// No description provided for @joinRoomNoResults.
  ///
  /// In en, this message translates to:
  /// **'No public communities matched.'**
  String get joinRoomNoResults;

  /// No description provided for @joinRoomPermissionOnly.
  ///
  /// In en, this message translates to:
  /// **'Permission-based communities can only be joined using their code.'**
  String get joinRoomPermissionOnly;

  /// No description provided for @joinRoomMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String joinRoomMembers(int count);

  /// No description provided for @joinRoomJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinRoomJoin;

  /// No description provided for @roomDetailSettings.
  ///
  /// In en, this message translates to:
  /// **'Community settings'**
  String get roomDetailSettings;

  /// No description provided for @roomDetailMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get roomDetailMembers;

  /// No description provided for @roomDetailCouldNotLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load posts.'**
  String get roomDetailCouldNotLoadPosts;

  /// No description provided for @roomDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No huddles in this community yet'**
  String get roomDetailEmptyTitle;

  /// No description provided for @roomDetailEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo from the camera to be the first.'**
  String get roomDetailEmptyBody;

  /// No description provided for @roomSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Settings'**
  String get roomSettingsTitle;

  /// No description provided for @roomSettingsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename community'**
  String get roomSettingsRename;

  /// No description provided for @roomSettingsModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get roomSettingsModeration;

  /// No description provided for @roomSettingsPendingJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Join Requests'**
  String get roomSettingsPendingJoinRequests;

  /// No description provided for @roomSettingsMembersCount.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String roomSettingsMembersCount(int count);

  /// No description provided for @roomSettingsLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Community'**
  String get roomSettingsLeaveRoom;

  /// No description provided for @roomSettingsDeleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete Community'**
  String get roomSettingsDeleteRoom;

  /// No description provided for @roomSettingsPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get roomSettingsPublic;

  /// No description provided for @roomSettingsPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get roomSettingsPermission;

  /// No description provided for @roomSettingsRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Community code'**
  String get roomSettingsRoomCode;

  /// No description provided for @roomSettingsCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get roomSettingsCodeCopied;

  /// No description provided for @roomSettingsShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join my \"{name}\" community on Huddlex — use code {code}'**
  String roomSettingsShareMessage(String name, String code);

  /// No description provided for @roomSettingsShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Join {name} on Huddlex'**
  String roomSettingsShareSubject(String name);

  /// No description provided for @roomSettingsRequirePostApproval.
  ///
  /// In en, this message translates to:
  /// **'Require post approval'**
  String get roomSettingsRequirePostApproval;

  /// No description provided for @roomSettingsRequirePostApprovalDescription.
  ///
  /// In en, this message translates to:
  /// **'Posts by regular members wait for admin approval. Admins and trusted users always post immediately.'**
  String get roomSettingsRequirePostApprovalDescription;

  /// No description provided for @roomSettingsReviewPending.
  ///
  /// In en, this message translates to:
  /// **'Review pending posts'**
  String get roomSettingsReviewPending;

  /// No description provided for @roomSettingsNoPending.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get roomSettingsNoPending;

  /// No description provided for @roomSettingsLocationLock.
  ///
  /// In en, this message translates to:
  /// **'Location lock'**
  String get roomSettingsLocationLock;

  /// No description provided for @roomSettingsLocationLockToggle.
  ///
  /// In en, this message translates to:
  /// **'Lock posting to a place'**
  String get roomSettingsLocationLockToggle;

  /// No description provided for @roomSettingsLocationLockDescription.
  ///
  /// In en, this message translates to:
  /// **'When on, posts from outside the pinned area need admin approval. Admins always post immediately.'**
  String get roomSettingsLocationLockDescription;

  /// No description provided for @roomSettingsLocationPinSet.
  ///
  /// In en, this message translates to:
  /// **'Pinned at {lat}, {lng}'**
  String roomSettingsLocationPinSet(String lat, String lng);

  /// No description provided for @roomSettingsLocationPinNotSet.
  ///
  /// In en, this message translates to:
  /// **'No pin set yet'**
  String get roomSettingsLocationPinNotSet;

  /// No description provided for @roomSettingsLocationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Pin my current location'**
  String get roomSettingsLocationUseCurrent;

  /// No description provided for @roomSettingsLocationRadius.
  ///
  /// In en, this message translates to:
  /// **'Allowed radius'**
  String get roomSettingsLocationRadius;

  /// No description provided for @roomSettingsLocationFailedServices.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to set the pin.'**
  String get roomSettingsLocationFailedServices;

  /// No description provided for @roomSettingsLocationFailedPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get roomSettingsLocationFailedPermission;

  /// No description provided for @roomSettingsLocationFailedPermissionForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission was permanently denied. Open Settings to enable it.'**
  String get roomSettingsLocationFailedPermissionForever;

  /// No description provided for @roomSettingsLocationFailedTimeout.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read your location in time. Try again outdoors.'**
  String get roomSettingsLocationFailedTimeout;

  /// No description provided for @roomSettingsLocationFailedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read your location.'**
  String get roomSettingsLocationFailedUnknown;

  /// No description provided for @accountFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get accountFeedback;

  /// No description provided for @accountFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bug, idea, or a thank-you — we read everything'**
  String get accountFeedbackSubtitle;

  /// No description provided for @accountFeedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'Huddlex feedback'**
  String get accountFeedbackSubject;

  /// No description provided for @accountFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'Hey! Here\'s what happened / what I\'d love to see:\n\n'**
  String get accountFeedbackBody;

  /// No description provided for @accountFeedbackFailedToOpen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your email app. Please write to obaidabakjaji@gmail.com.'**
  String get accountFeedbackFailedToOpen;

  /// No description provided for @roomSettingsTrustedTag.
  ///
  /// In en, this message translates to:
  /// **'Trusted — bypasses post approval'**
  String get roomSettingsTrustedTag;

  /// No description provided for @roomSettingsMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get roomSettingsMakeAdmin;

  /// No description provided for @roomSettingsRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get roomSettingsRemoveAdmin;

  /// No description provided for @roomSettingsRemoveTrusted.
  ///
  /// In en, this message translates to:
  /// **'Remove trusted status'**
  String get roomSettingsRemoveTrusted;

  /// No description provided for @roomSettingsMarkTrusted.
  ///
  /// In en, this message translates to:
  /// **'Mark as trusted'**
  String get roomSettingsMarkTrusted;

  /// No description provided for @roomSettingsRemoveFromRoom.
  ///
  /// In en, this message translates to:
  /// **'Remove from community'**
  String get roomSettingsRemoveFromRoom;

  /// No description provided for @roomSettingsRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get roomSettingsRemoveMemberTitle;

  /// No description provided for @roomSettingsRemoveMemberBody.
  ///
  /// In en, this message translates to:
  /// **'{member} will be removed from \"{room}\".'**
  String roomSettingsRemoveMemberBody(String member, String room);

  /// No description provided for @roomSettingsFailedUpdatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo: {error}'**
  String roomSettingsFailedUpdatePhoto(String error);

  /// No description provided for @roomSettingsNewName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get roomSettingsNewName;

  /// No description provided for @roomSettingsLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave community?'**
  String get roomSettingsLeaveTitle;

  /// No description provided for @roomSettingsLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will stop receiving huddles from \"{name}\".'**
  String roomSettingsLeaveBody(String name);

  /// No description provided for @roomSettingsLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get roomSettingsLeave;

  /// No description provided for @roomSettingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete community?'**
  String get roomSettingsDeleteTitle;

  /// No description provided for @roomSettingsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently deleted for all members. This cannot be undone.'**
  String roomSettingsDeleteBody(String name);

  /// No description provided for @pendingPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending — {room}'**
  String pendingPostsTitle(String room);

  /// No description provided for @pendingPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for approval.'**
  String get pendingPostsEmpty;

  /// No description provided for @pendingPostsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get pendingPostsReject;

  /// No description provided for @pendingPostsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get pendingPostsApprove;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'New Huddle'**
  String get cameraTitle;

  /// No description provided for @cameraNoRooms.
  ///
  /// In en, this message translates to:
  /// **'Join or create a community first to post huddles.'**
  String get cameraNoRooms;

  /// No description provided for @cameraProcessingVideo.
  ///
  /// In en, this message translates to:
  /// **'Processing video…'**
  String get cameraProcessingVideo;

  /// No description provided for @cameraMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get cameraMuted;

  /// No description provided for @cameraCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Capture a photo or 6-second clip'**
  String get cameraCaptureHint;

  /// No description provided for @cameraPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get cameraPhoto;

  /// No description provided for @cameraVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get cameraVideo;

  /// No description provided for @cameraPhotoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo from gallery'**
  String get cameraPhotoFromGallery;

  /// No description provided for @cameraVideoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Video from gallery'**
  String get cameraVideoFromGallery;

  /// No description provided for @cameraRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get cameraRetake;

  /// No description provided for @cameraPostClip.
  ///
  /// In en, this message translates to:
  /// **'Post Clip'**
  String get cameraPostClip;

  /// No description provided for @cameraPostMomento.
  ///
  /// In en, this message translates to:
  /// **'Post Huddle'**
  String get cameraPostMomento;

  /// No description provided for @cameraCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional)'**
  String get cameraCaptionHint;

  /// No description provided for @cameraPostTo.
  ///
  /// In en, this message translates to:
  /// **'Post to'**
  String get cameraPostTo;

  /// No description provided for @cameraActiveRoomsCount.
  ///
  /// In en, this message translates to:
  /// **'Active communities ({count})'**
  String cameraActiveRoomsCount(int count);

  /// No description provided for @cameraAllRoomsCount.
  ///
  /// In en, this message translates to:
  /// **'All communities ({count})'**
  String cameraAllRoomsCount(int count);

  /// No description provided for @cameraPickRooms.
  ///
  /// In en, this message translates to:
  /// **'Pick…'**
  String get cameraPickRooms;

  /// No description provided for @cameraPickAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one community'**
  String get cameraPickAtLeastOne;

  /// No description provided for @cameraPostedTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Posted to 1 community!} other{Posted to {count} communities!}}'**
  String cameraPostedTo(int count);

  /// No description provided for @cameraPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post pending admin approval.} other{{count} posts pending admin approval.}}'**
  String cameraPendingApproval(int count);

  /// No description provided for @cameraLiveAndPending.
  ///
  /// In en, this message translates to:
  /// **'{live} live, {pending} pending admin approval.'**
  String cameraLiveAndPending(int live, int pending);

  /// No description provided for @cameraFailedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String cameraFailedToSend(String error);

  /// No description provided for @cameraCouldNotProcessVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not process video.'**
  String get cameraCouldNotProcessVideo;

  /// No description provided for @cameraVideoTooLong.
  ///
  /// In en, this message translates to:
  /// **'Video must be 6 seconds or shorter.'**
  String get cameraVideoTooLong;

  /// No description provided for @cameraCouldNotPoster.
  ///
  /// In en, this message translates to:
  /// **'Could not generate poster frame.'**
  String get cameraCouldNotPoster;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountTitle;

  /// No description provided for @accountActiveRooms.
  ///
  /// In en, this message translates to:
  /// **'Active Communities'**
  String get accountActiveRooms;

  /// No description provided for @accountActiveRoomsDescription.
  ///
  /// In en, this message translates to:
  /// **'Posts go here by default. Toggle on/off in the Communities tab.'**
  String get accountActiveRoomsDescription;

  /// No description provided for @accountFavoriteRooms.
  ///
  /// In en, this message translates to:
  /// **'Favorite Communities'**
  String get accountFavoriteRooms;

  /// No description provided for @accountFavoriteRoomsDescription.
  ///
  /// In en, this message translates to:
  /// **'Favorites bubble to the front of the feed and the widget rotation.'**
  String get accountFavoriteRoomsDescription;

  /// No description provided for @accountBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get accountBlockedUsers;

  /// No description provided for @accountLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get accountLegal;

  /// No description provided for @accountTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get accountTermsOfService;

  /// No description provided for @accountPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get accountPrivacyPolicy;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get accountSignOut;

  /// No description provided for @accountDeleteMy.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get accountDeleteMy;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove your account, memberships in all communities, and favorites. Posts will expire naturally. This cannot be undone.'**
  String get accountDeleteBody;

  /// No description provided for @accountReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign out and sign back in, then try deleting again.'**
  String get accountReauthRequired;

  /// No description provided for @accountFailedWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed: {message}'**
  String accountFailedWithMessage(String message);

  /// No description provided for @accountRoomsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 community} other{{count} communities}}'**
  String accountRoomsCount(int count);

  /// No description provided for @accountEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accountEditProfile;

  /// No description provided for @accountStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String accountStreakDays(int count);

  /// No description provided for @accountStreakBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {count} days'**
  String accountStreakBest(int count);

  /// No description provided for @accountStreakKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep it going — post today'**
  String get accountStreakKeepGoing;

  /// No description provided for @accountNoBlocked.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get accountNoBlocked;

  /// No description provided for @accountUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get accountUnblock;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get accountLanguageSystem;

  /// No description provided for @accountNoActiveRooms.
  ///
  /// In en, this message translates to:
  /// **'No active communities'**
  String get accountNoActiveRooms;

  /// No description provided for @accountNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get accountNoFavorites;

  /// No description provided for @roomSettingsCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get roomSettingsCreator;

  /// No description provided for @roomSettingsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roomSettingsAdmin;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileTapPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get editProfileTapPhoto;

  /// No description provided for @editProfileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get editProfileDisplayName;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get editProfileNameRequired;

  /// No description provided for @editProfileFailedSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String editProfileFailedSave(String error);

  /// No description provided for @postActionsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this post'**
  String get postActionsReportTitle;

  /// No description provided for @postActionsReportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this post?'**
  String get postActionsReportPrompt;

  /// No description provided for @postActionsReportPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Optional — describe what is wrong'**
  String get postActionsReportPlaceholder;

  /// No description provided for @postActionsReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thanks.'**
  String get postActionsReportSubmitted;

  /// No description provided for @postActionsBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String postActionsBlockUser(String name);

  /// No description provided for @postActionsBlockDescription.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see their posts in any community'**
  String get postActionsBlockDescription;

  /// No description provided for @postActionsUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} blocked.'**
  String postActionsUserBlocked(String name);

  /// No description provided for @postActionsOwnPost.
  ///
  /// In en, this message translates to:
  /// **'This is your own post'**
  String get postActionsOwnPost;

  /// No description provided for @postActionsNoActions.
  ///
  /// In en, this message translates to:
  /// **'No moderation actions available'**
  String get postActionsNoActions;

  /// No description provided for @postActionsBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String postActionsBlockTitle(String name);

  /// No description provided for @postActionsBlockBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see {name}\'s posts in any community. They won\'t be notified.'**
  String postActionsBlockBody(String name);

  /// No description provided for @postActionsBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get postActionsBlock;

  /// No description provided for @postActionsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this huddle'**
  String get postActionsDelete;

  /// No description provided for @postActionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this huddle?'**
  String get postActionsDeleteTitle;

  /// No description provided for @postActionsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It\'ll be removed from the community immediately. This can\'t be undone.'**
  String get postActionsDeleteBody;

  /// No description provided for @postActionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get postActionsDeleted;

  /// No description provided for @likedByCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Liked by 1} other{Liked by {count}}}'**
  String likedByCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

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
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
