// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Huddlex';

  @override
  String get appTagline => 'Every huddle, shared beautifully';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonShare => 'Share';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String commonFailedWithError(String error) {
    return 'Failed: $error';
  }

  @override
  String get commonYouAreOffline => 'You are offline';

  @override
  String get authYourName => 'Your name';

  @override
  String get authYourNameHint => 'Enter your name';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter a valid email';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Min 6 characters';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get authByCreatingYouAgree =>
      'By creating an account you agree to our ';

  @override
  String get authBySigningInYouAgree => 'By signing in you agree to our ';

  @override
  String get authTerms => 'Terms';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authResetPasswordDescription =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get authSend => 'Send';

  @override
  String authResetLinkSent(String email) {
    return 'Reset link sent to $email';
  }

  @override
  String get verifyTitle => 'Check your email';

  @override
  String verifyDescription(String email) {
    return 'We sent a 6-digit code to $email. Enter it below to confirm your account.';
  }

  @override
  String get verifyCodeSent => 'Code sent — check your inbox.';

  @override
  String get verifyCodeSentNew => 'New code sent — check your inbox.';

  @override
  String get verifyCodeFailed =>
      'Could not send a code. Tap resend to try again.';

  @override
  String get verifyCodeFailedNew => 'Could not send a new code. Try again.';

  @override
  String get verifySomethingWrong => 'Something went wrong. Try again.';

  @override
  String verifyResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get verifyResend => 'Resend code';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Huddlex';

  @override
  String get onboardingWelcomeBody =>
      'Share unfiltered moments with the people closest to you. No likes counts, no algorithms — just little glimpses of your day.';

  @override
  String get onboardingRoomsTitle => 'Create or join Communities';

  @override
  String get onboardingRoomsBody =>
      'A Community is a private space for sharing photos. Start one for your family, your trip, your group of friends — and invite people with a 6-character code.';

  @override
  String get onboardingExpireTitle => 'Photos disappear in 6 hours';

  @override
  String get onboardingExpireBody =>
      'Every photo expires automatically. Snap, share, and move on — no archive, no pressure.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get homeFeed => 'Feed';

  @override
  String get homeRooms => 'Communities';

  @override
  String get homeAccount => 'Account';

  @override
  String get homeNewMomento => 'New Huddle';

  @override
  String get homeCouldNotLoadAccount => 'Couldn\'t load your account.';

  @override
  String get homeCouldNotLoadRooms => 'Couldn\'t load your communities.';

  @override
  String get homeCouldNotLoadPosts => 'Couldn\'t load posts.';

  @override
  String get homeNoRoomsTitle => 'No communities yet';

  @override
  String get homeNoRoomsHomeBody =>
      'Open the Communities tab to create or join one.';

  @override
  String get homeNoMomentosTitle => 'No huddles yet';

  @override
  String get homeNoMomentosBody =>
      'Take a photo and share it with your communities!';

  @override
  String get homeExpired => 'Expired';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m remaining';
  }

  @override
  String get roomsMyRooms => 'My Communities';

  @override
  String get roomsJoinByCode => 'Join by code';

  @override
  String get roomsCreateRoom => 'Create Community';

  @override
  String get roomsJoinRoom => 'Join Community';

  @override
  String get roomsEmptyTitle => 'No communities yet';

  @override
  String get roomsEmptyBody =>
      'Create a new community or join one with a code to start sharing huddles.';

  @override
  String get roomsCodePrefix => 'Code ';

  @override
  String get roomsFavorite => 'Favorite';

  @override
  String get roomsUnfavorite => 'Unfavorite';

  @override
  String get roomsActivate => 'Activate';

  @override
  String get roomsDeactivate => 'Deactivate';

  @override
  String get createRoomTitle => 'Create Community';

  @override
  String get createRoomPhotoLabel => 'Community photo (optional)';

  @override
  String get createRoomNameLabel => 'Community name';

  @override
  String get createRoomNameHint => 'e.g. Family, Trip 2026, Best Friends';

  @override
  String get createRoomNameRequired => 'Please enter a community name';

  @override
  String get createRoomWhoCanJoin => 'Who can join?';

  @override
  String get createRoomPublic => 'Public';

  @override
  String get createRoomPublicDescription =>
      'Anyone with the community code can join instantly';

  @override
  String get createRoomPermission => 'Permission';

  @override
  String get createRoomPermissionDescription =>
      'New members must be approved by an admin';

  @override
  String get joinRoomTitle => 'Join Community';

  @override
  String get joinRoomHaveCode => 'Have a code?';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix => 'Community codes are 6 characters';

  @override
  String get joinRoomNotFound => 'No community found with that code';

  @override
  String joinRoomRequestSent(String name) {
    return 'Request sent. Waiting for an admin of \"$name\" to approve.';
  }

  @override
  String get joinRoomSearch => 'Or search public communities';

  @override
  String get joinRoomSearchHint => 'Community name…';

  @override
  String get joinRoomNoResults => 'No public communities matched.';

  @override
  String get joinRoomPermissionOnly =>
      'Permission-based communities can only be joined using their code.';

  @override
  String joinRoomMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get joinRoomJoin => 'Join';

  @override
  String get roomDetailSettings => 'Community settings';

  @override
  String get roomDetailMembers => 'Members';

  @override
  String get roomDetailCouldNotLoadPosts => 'Couldn\'t load posts.';

  @override
  String get roomDetailEmptyTitle => 'No huddles in this community yet';

  @override
  String get roomDetailEmptyBody =>
      'Take a photo from the camera to be the first.';

  @override
  String get roomSettingsTitle => 'Community Settings';

  @override
  String get roomSettingsRename => 'Rename community';

  @override
  String get roomSettingsModeration => 'Moderation';

  @override
  String get roomSettingsPendingJoinRequests => 'Pending Join Requests';

  @override
  String roomSettingsMembersCount(int count) {
    return 'Members ($count)';
  }

  @override
  String get roomSettingsLeaveRoom => 'Leave Community';

  @override
  String get roomSettingsDeleteRoom => 'Delete Community';

  @override
  String get roomSettingsPublic => 'Public';

  @override
  String get roomSettingsPermission => 'Permission';

  @override
  String get roomSettingsRoomCode => 'Community code';

  @override
  String get roomSettingsCodeCopied => 'Code copied!';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return 'Join my \"$name\" community on Huddlex — use code $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return 'Join $name on Huddlex';
  }

  @override
  String get roomSettingsRequirePostApproval => 'Require post approval';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      'Posts by regular members wait for admin approval. Admins and trusted users always post immediately.';

  @override
  String get roomSettingsReviewPending => 'Review pending posts';

  @override
  String get roomSettingsNoPending => 'No pending requests';

  @override
  String get roomSettingsTrustedTag => 'Trusted — bypasses post approval';

  @override
  String get roomSettingsMakeAdmin => 'Make admin';

  @override
  String get roomSettingsRemoveAdmin => 'Remove admin';

  @override
  String get roomSettingsRemoveTrusted => 'Remove trusted status';

  @override
  String get roomSettingsMarkTrusted => 'Mark as trusted';

  @override
  String get roomSettingsRemoveFromRoom => 'Remove from community';

  @override
  String get roomSettingsRemoveMemberTitle => 'Remove member?';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return '$member will be removed from \"$room\".';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return 'Failed to update photo: $error';
  }

  @override
  String get roomSettingsNewName => 'New name';

  @override
  String get roomSettingsLeaveTitle => 'Leave community?';

  @override
  String roomSettingsLeaveBody(String name) {
    return 'You will stop receiving huddles from \"$name\".';
  }

  @override
  String get roomSettingsLeave => 'Leave';

  @override
  String get roomSettingsDeleteTitle => 'Delete community?';

  @override
  String roomSettingsDeleteBody(String name) {
    return '\"$name\" will be permanently deleted for all members. This cannot be undone.';
  }

  @override
  String pendingPostsTitle(String room) {
    return 'Pending — $room';
  }

  @override
  String get pendingPostsEmpty => 'Nothing waiting for approval.';

  @override
  String get pendingPostsReject => 'Reject';

  @override
  String get pendingPostsApprove => 'Approve';

  @override
  String get cameraTitle => 'New Huddle';

  @override
  String get cameraNoRooms =>
      'Join or create a community first to post huddles.';

  @override
  String get cameraProcessingVideo => 'Processing video…';

  @override
  String get cameraMuted => 'Muted';

  @override
  String get cameraCaptureHint => 'Capture a photo or 6-second clip';

  @override
  String get cameraPhoto => 'Photo';

  @override
  String get cameraVideo => 'Video';

  @override
  String get cameraPhotoFromGallery => 'Photo from gallery';

  @override
  String get cameraVideoFromGallery => 'Video from gallery';

  @override
  String get cameraRetake => 'Retake';

  @override
  String get cameraPostClip => 'Post Clip';

  @override
  String get cameraPostMomento => 'Post Huddle';

  @override
  String get cameraCaptionHint => 'Add a caption (optional)';

  @override
  String get cameraPostTo => 'Post to';

  @override
  String cameraActiveRoomsCount(int count) {
    return 'Active communities ($count)';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return 'All communities ($count)';
  }

  @override
  String get cameraPickRooms => 'Pick…';

  @override
  String get cameraPickAtLeastOne => 'Pick at least one community';

  @override
  String cameraPostedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Posted to $count communities!',
      one: 'Posted to 1 community!',
    );
    return '$_temp0';
  }

  @override
  String cameraPendingApproval(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts pending admin approval.',
      one: '1 post pending admin approval.',
    );
    return '$_temp0';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live live, $pending pending admin approval.';
  }

  @override
  String cameraFailedToSend(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get cameraCouldNotProcessVideo => 'Could not process video.';

  @override
  String get cameraVideoTooLong => 'Video must be 6 seconds or shorter.';

  @override
  String get cameraCouldNotPoster => 'Could not generate poster frame.';

  @override
  String get accountTitle => 'My Account';

  @override
  String get accountActiveRooms => 'Active Communities';

  @override
  String get accountActiveRoomsDescription =>
      'Posts go here by default. Toggle on/off in the Communities tab.';

  @override
  String get accountFavoriteRooms => 'Favorite Communities';

  @override
  String get accountFavoriteRoomsDescription =>
      'Favorites bubble to the front of the feed and the widget rotation.';

  @override
  String get accountBlockedUsers => 'Blocked Users';

  @override
  String get accountLegal => 'Legal';

  @override
  String get accountTermsOfService => 'Terms of Service';

  @override
  String get accountPrivacyPolicy => 'Privacy Policy';

  @override
  String get accountSignOut => 'Sign Out';

  @override
  String get accountDeleteMy => 'Delete my account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String get accountDeleteBody =>
      'This will permanently remove your account, memberships in all communities, and favorites. Posts will expire naturally. This cannot be undone.';

  @override
  String get accountReauthRequired =>
      'Please sign out and sign back in, then try deleting again.';

  @override
  String accountFailedWithMessage(String message) {
    return 'Failed: $message';
  }

  @override
  String accountRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count communities',
      one: '1 community',
    );
    return '$_temp0';
  }

  @override
  String get accountEditProfile => 'Edit profile';

  @override
  String accountStreakDays(int count) {
    return '$count-day streak';
  }

  @override
  String accountStreakBest(int count) {
    return 'Best: $count days';
  }

  @override
  String get accountStreakKeepGoing => 'Keep it going — post today';

  @override
  String get accountNoBlocked => 'No blocked users';

  @override
  String get accountUnblock => 'Unblock';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountLanguageSystem => 'System default';

  @override
  String get accountNoActiveRooms => 'No active communities';

  @override
  String get accountNoFavorites => 'No favorites';

  @override
  String get roomSettingsCreator => 'Creator';

  @override
  String get roomSettingsAdmin => 'Admin';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileTapPhoto => 'Tap to change photo';

  @override
  String get editProfileDisplayName => 'Display name';

  @override
  String get editProfileNameRequired => 'Name cannot be empty';

  @override
  String editProfileFailedSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get postActionsReportTitle => 'Report this post';

  @override
  String get postActionsReportPrompt => 'Why are you reporting this post?';

  @override
  String get postActionsReportPlaceholder =>
      'Optional — describe what is wrong';

  @override
  String get postActionsReportSubmitted => 'Report submitted. Thanks.';

  @override
  String postActionsBlockUser(String name) {
    return 'Block $name';
  }

  @override
  String get postActionsBlockDescription =>
      'You won\'t see their posts in any community';

  @override
  String postActionsUserBlocked(String name) {
    return '$name blocked.';
  }

  @override
  String get postActionsOwnPost => 'This is your own post';

  @override
  String get postActionsNoActions => 'No moderation actions available';

  @override
  String postActionsBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String postActionsBlockBody(String name) {
    return 'You won\'t see $name\'s posts in any community. They won\'t be notified.';
  }

  @override
  String get postActionsBlock => 'Block';

  @override
  String likedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked by $count',
      one: 'Liked by 1',
    );
    return '$_temp0';
  }
}
