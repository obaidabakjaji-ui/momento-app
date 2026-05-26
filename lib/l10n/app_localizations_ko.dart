// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Huddlex';

  @override
  String get appTagline => '모든 순간을, 아름답게 공유하세요';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonRemove => '제거';

  @override
  String get commonCopy => '복사';

  @override
  String get commonShare => '공유';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonSubmit => '제출';

  @override
  String get commonSomethingWentWrong => '문제가 발생했습니다';

  @override
  String commonFailedWithError(String error) {
    return '실패: $error';
  }

  @override
  String get commonYouAreOffline => '오프라인 상태입니다';

  @override
  String get authYourName => '이름';

  @override
  String get authYourNameHint => '이름을 입력하세요';

  @override
  String get authEmail => '이메일';

  @override
  String get authEmailHint => '올바른 이메일을 입력하세요';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authPassword => '비밀번호';

  @override
  String get authPasswordHint => '최소 6자';

  @override
  String get authCreateAccount => '계정 만들기';

  @override
  String get authSignIn => '로그인';

  @override
  String get authSignOut => '로그아웃';

  @override
  String get authForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get authContinueWithGoogle => 'Google로 계속하기';

  @override
  String get authAlreadyHaveAccount => '이미 계정이 있나요? 로그인';

  @override
  String get authNoAccount => '계정이 없나요? 가입';

  @override
  String get authByCreatingYouAgree => '계정을 만들면 다음에 동의하게 됩니다: ';

  @override
  String get authBySigningInYouAgree => '로그인하면 다음에 동의하게 됩니다: ';

  @override
  String get authTerms => '이용약관';

  @override
  String get authPrivacyPolicy => '개인정보 처리방침';

  @override
  String get authResetPasswordTitle => '비밀번호 재설정';

  @override
  String get authResetPasswordDescription => '이메일을 입력하시면 비밀번호 재설정 링크를 보내드립니다.';

  @override
  String get authSend => '보내기';

  @override
  String authResetLinkSent(String email) {
    return '$email로 재설정 링크를 보냈습니다';
  }

  @override
  String get verifyTitle => '이메일을 확인하세요';

  @override
  String verifyDescription(String email) {
    return '$email로 6자리 코드를 보냈습니다. 아래에 입력하여 계정을 확인하세요.';
  }

  @override
  String get verifyCodeSent => '코드 전송됨 — 받은편지함을 확인하세요.';

  @override
  String get verifyCodeSentNew => '새 코드 전송됨 — 받은편지함을 확인하세요.';

  @override
  String get verifyCodeFailed => '코드를 보내지 못했습니다. 다시 보내기를 눌러주세요.';

  @override
  String get verifyCodeFailedNew => '새 코드를 보내지 못했습니다. 다시 시도하세요.';

  @override
  String get verifySomethingWrong => '문제가 발생했습니다. 다시 시도하세요.';

  @override
  String verifyResendIn(int seconds) {
    return '$seconds초 후 다시 보내기';
  }

  @override
  String get verifyResend => '코드 다시 보내기';

  @override
  String get onboardingWelcomeTitle => 'Huddlex에 오신 것을 환영합니다';

  @override
  String get onboardingWelcomeBody =>
      '가까운 사람들과 꾸미지 않은 순간을 공유하세요. 좋아요 수도, 알고리즘도 없이 — 그저 일상의 작은 조각들을.';

  @override
  String get onboardingRoomsTitle => '커뮤니티를 만들거나 참여하세요';

  @override
  String get onboardingRoomsBody =>
      '커뮤니티는 사진을 공유하는 비공개 공간입니다. 가족, 여행, 친구 그룹을 위해 만들고, 6자 코드로 초대하세요.';

  @override
  String get onboardingExpireTitle => '사진은 6시간 후에 사라집니다';

  @override
  String get onboardingExpireBody =>
      '모든 사진은 자동으로 만료됩니다. 찍고, 공유하고, 넘어가세요 — 보관도, 부담도 없이.';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingGetStarted => '시작하기';

  @override
  String get homeFeed => '피드';

  @override
  String get homeRooms => '커뮤니티';

  @override
  String get homeAccount => '계정';

  @override
  String get homeNewMomento => '새 Huddle';

  @override
  String get homeCouldNotLoadAccount => '계정을 불러올 수 없습니다.';

  @override
  String get homeCouldNotLoadRooms => '커뮤니티를 불러올 수 없습니다.';

  @override
  String get homeCouldNotLoadPosts => '게시물을 불러올 수 없습니다.';

  @override
  String get homeNoRoomsTitle => '아직 커뮤니티가 없습니다';

  @override
  String get homeNoRoomsHomeBody => '커뮤니티 탭을 열어 만들거나 참여하세요.';

  @override
  String get homeNoMomentosTitle => '아직 Huddle가 없습니다';

  @override
  String get homeNoMomentosBody => '사진을 찍어 커뮤니티와 공유하세요!';

  @override
  String get homeExpired => '만료됨';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return '$hours시간 $minutes분 남음';
  }

  @override
  String get roomsMyRooms => '내 커뮤니티';

  @override
  String get roomsJoinByCode => '코드로 참여';

  @override
  String get roomsCreateRoom => '커뮤니티 만들기';

  @override
  String get roomsJoinRoom => '커뮤니티 참여';

  @override
  String get roomsEmptyTitle => '아직 커뮤니티가 없습니다';

  @override
  String get roomsEmptyBody => '새 커뮤니티를 만들거나 코드로 참여하여 Huddle를 공유하세요.';

  @override
  String get roomsCodePrefix => '코드 ';

  @override
  String get roomsFavorite => '즐겨찾기';

  @override
  String get roomsUnfavorite => '즐겨찾기 해제';

  @override
  String get roomsActivate => '활성화';

  @override
  String get roomsDeactivate => '비활성화';

  @override
  String get createRoomTitle => '커뮤니티 만들기';

  @override
  String get createRoomPhotoLabel => '커뮤니티 사진 (선택)';

  @override
  String get createRoomNameLabel => '커뮤니티 이름';

  @override
  String get createRoomNameHint => '예: 가족, 2026 여행, 베스트 프렌즈';

  @override
  String get createRoomNameRequired => '커뮤니티 이름을 입력하세요';

  @override
  String get createRoomWhoCanJoin => '누가 참여할 수 있나요?';

  @override
  String get createRoomPublic => '공개';

  @override
  String get createRoomPublicDescription => '코드만 알면 누구나 즉시 참여 가능';

  @override
  String get createRoomPermission => '승인 필요';

  @override
  String get createRoomPermissionDescription => '새 멤버는 관리자의 승인이 필요합니다';

  @override
  String get joinRoomTitle => '커뮤니티 참여';

  @override
  String get joinRoomHaveCode => '코드가 있나요?';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix => '커뮤니티 코드는 6자입니다';

  @override
  String get joinRoomNotFound => '해당 코드의 커뮤니티를 찾을 수 없습니다';

  @override
  String joinRoomRequestSent(String name) {
    return '요청을 보냈습니다. \"$name\"의 관리자 승인을 기다리는 중.';
  }

  @override
  String get joinRoomSearch => '또는 공개 커뮤니티 검색';

  @override
  String get joinRoomSearchHint => '커뮤니티 이름…';

  @override
  String get joinRoomNoResults => '일치하는 공개 커뮤니티가 없습니다.';

  @override
  String get joinRoomPermissionOnly => '승인 필요 커뮤니티는 코드로만 참여할 수 있습니다.';

  @override
  String joinRoomMembers(int count) {
    return '$count명';
  }

  @override
  String get joinRoomJoin => '참여';

  @override
  String get roomDetailSettings => '커뮤니티 설정';

  @override
  String get roomDetailMembers => '멤버';

  @override
  String get roomDetailCouldNotLoadPosts => '게시물을 불러올 수 없습니다.';

  @override
  String get roomDetailEmptyTitle => '아직 이 커뮤니티에 Huddle가 없습니다';

  @override
  String get roomDetailEmptyBody => '카메라로 사진을 찍어 첫 번째가 되어 보세요.';

  @override
  String get roomSettingsTitle => '커뮤니티 설정';

  @override
  String get roomSettingsRename => '커뮤니티 이름 변경';

  @override
  String get roomSettingsModeration => '관리';

  @override
  String get roomSettingsPendingJoinRequests => '참여 대기 요청';

  @override
  String roomSettingsMembersCount(int count) {
    return '멤버 ($count)';
  }

  @override
  String get roomSettingsLeaveRoom => '커뮤니티 떠나기';

  @override
  String get roomSettingsDeleteRoom => '커뮤니티 삭제';

  @override
  String get roomSettingsPublic => '공개';

  @override
  String get roomSettingsPermission => '승인 필요';

  @override
  String get roomSettingsRoomCode => '커뮤니티 코드';

  @override
  String get roomSettingsCodeCopied => '코드가 복사되었습니다!';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return 'Huddlex에서 내 \"$name\" 커뮤니티에 참여하세요 — 코드 $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return 'Huddlex의 $name에 참여';
  }

  @override
  String get roomSettingsRequirePostApproval => '게시물 승인 필요';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      '일반 멤버의 게시물은 관리자 승인을 기다립니다. 관리자와 신뢰 사용자는 즉시 게시됩니다.';

  @override
  String get roomSettingsReviewPending => '대기 중인 게시물 검토';

  @override
  String get roomSettingsNoPending => '대기 중인 요청 없음';

  @override
  String get roomSettingsTrustedTag => '신뢰 — 게시물 승인 생략';

  @override
  String get roomSettingsMakeAdmin => '관리자로 지정';

  @override
  String get roomSettingsRemoveAdmin => '관리자 해제';

  @override
  String get roomSettingsRemoveTrusted => '신뢰 상태 해제';

  @override
  String get roomSettingsMarkTrusted => '신뢰로 지정';

  @override
  String get roomSettingsRemoveFromRoom => '커뮤니티에서 제거';

  @override
  String get roomSettingsRemoveMemberTitle => '멤버를 제거할까요?';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return '$member이(가) \"$room\"에서 제거됩니다.';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return '사진 업데이트 실패: $error';
  }

  @override
  String get roomSettingsNewName => '새 이름';

  @override
  String get roomSettingsLeaveTitle => '커뮤니티를 떠날까요?';

  @override
  String roomSettingsLeaveBody(String name) {
    return '\"$name\"의 Huddle를 더 이상 받지 않습니다.';
  }

  @override
  String get roomSettingsLeave => '떠나기';

  @override
  String get roomSettingsDeleteTitle => '커뮤니티를 삭제할까요?';

  @override
  String roomSettingsDeleteBody(String name) {
    return '\"$name\"이(가) 모든 멤버에게서 영구적으로 삭제됩니다. 되돌릴 수 없습니다.';
  }

  @override
  String pendingPostsTitle(String room) {
    return '대기 중 — $room';
  }

  @override
  String get pendingPostsEmpty => '승인 대기 중인 항목이 없습니다.';

  @override
  String get pendingPostsReject => '거부';

  @override
  String get pendingPostsApprove => '승인';

  @override
  String get cameraTitle => '새 Huddle';

  @override
  String get cameraNoRooms => 'Huddle를 게시하려면 먼저 커뮤니티를 만들거나 참여하세요.';

  @override
  String get cameraProcessingVideo => '동영상 처리 중…';

  @override
  String get cameraMuted => '음소거';

  @override
  String get cameraCaptureHint => '사진 또는 6초 클립을 촬영하세요';

  @override
  String get cameraPhoto => '사진';

  @override
  String get cameraVideo => '동영상';

  @override
  String get cameraPhotoFromGallery => '갤러리에서 사진';

  @override
  String get cameraVideoFromGallery => '갤러리에서 동영상';

  @override
  String get cameraRetake => '다시 찍기';

  @override
  String get cameraPostClip => '클립 게시';

  @override
  String get cameraPostMomento => 'Huddle 게시';

  @override
  String get cameraCaptionHint => '캡션 추가 (선택)';

  @override
  String get cameraPostTo => '게시 대상';

  @override
  String cameraActiveRoomsCount(int count) {
    return '활성 커뮤니티 ($count)';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return '모든 커뮤니티 ($count)';
  }

  @override
  String get cameraPickRooms => '선택…';

  @override
  String get cameraPickAtLeastOne => '커뮤니티를 하나 이상 선택하세요';

  @override
  String cameraPostedTo(int count) {
    return '$count개 커뮤니티에 게시되었습니다!';
  }

  @override
  String cameraPendingApproval(int count) {
    return '$count개 게시물이 관리자 승인 대기 중입니다.';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live개 게시, $pending개 승인 대기.';
  }

  @override
  String cameraFailedToSend(String error) {
    return '전송 실패: $error';
  }

  @override
  String get cameraCouldNotProcessVideo => '동영상을 처리할 수 없습니다.';

  @override
  String get cameraVideoTooLong => '동영상은 6초 이하여야 합니다.';

  @override
  String get cameraCouldNotPoster => '포스터 프레임을 생성할 수 없습니다.';

  @override
  String get accountTitle => '내 계정';

  @override
  String get accountActiveRooms => '활성 커뮤니티';

  @override
  String get accountActiveRoomsDescription =>
      '기본적으로 게시물이 여기로 갑니다. 커뮤니티 탭에서 켜고 끌 수 있습니다.';

  @override
  String get accountFavoriteRooms => '즐겨찾는 커뮤니티';

  @override
  String get accountFavoriteRoomsDescription => '즐겨찾기는 피드와 위젯 회전의 맨 앞에 표시됩니다.';

  @override
  String get accountBlockedUsers => '차단된 사용자';

  @override
  String get accountLegal => '법적 정보';

  @override
  String get accountTermsOfService => '서비스 약관';

  @override
  String get accountPrivacyPolicy => '개인정보 처리방침';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get accountDeleteMy => '내 계정 삭제';

  @override
  String get accountDeleteTitle => '계정을 삭제할까요?';

  @override
  String get accountDeleteBody =>
      '계정, 모든 커뮤니티 멤버십, 즐겨찾기가 영구적으로 제거됩니다. 게시물은 자연스럽게 만료됩니다. 되돌릴 수 없습니다.';

  @override
  String get accountReauthRequired => '로그아웃 후 다시 로그인한 다음 삭제를 다시 시도하세요.';

  @override
  String accountFailedWithMessage(String message) {
    return '실패: $message';
  }

  @override
  String accountRoomsCount(int count) {
    return '$count개 커뮤니티';
  }

  @override
  String get accountEditProfile => '프로필 편집';

  @override
  String accountStreakDays(int count) {
    return '$count일 연속';
  }

  @override
  String accountStreakBest(int count) {
    return '최고: $count일';
  }

  @override
  String get accountStreakKeepGoing => '계속해 보세요 — 오늘 게시하기';

  @override
  String get accountNoBlocked => '차단된 사용자가 없습니다';

  @override
  String get accountUnblock => '차단 해제';

  @override
  String get accountLanguage => '언어';

  @override
  String get accountLanguageSystem => '시스템 기본값';

  @override
  String get accountNoActiveRooms => '활성 커뮤니티 없음';

  @override
  String get accountNoFavorites => '즐겨찾기 없음';

  @override
  String get roomSettingsCreator => '생성자';

  @override
  String get roomSettingsAdmin => '관리자';

  @override
  String get editProfileTitle => '프로필 편집';

  @override
  String get editProfileTapPhoto => '사진을 변경하려면 누르세요';

  @override
  String get editProfileDisplayName => '표시 이름';

  @override
  String get editProfileNameRequired => '이름은 비워둘 수 없습니다';

  @override
  String editProfileFailedSave(String error) {
    return '저장 실패: $error';
  }

  @override
  String get postActionsReportTitle => '이 게시물 신고';

  @override
  String get postActionsReportPrompt => '왜 이 게시물을 신고하나요?';

  @override
  String get postActionsReportPlaceholder => '선택 사항 — 무엇이 잘못되었는지 설명하세요';

  @override
  String get postActionsReportSubmitted => '신고가 접수되었습니다. 감사합니다.';

  @override
  String postActionsBlockUser(String name) {
    return '$name 차단';
  }

  @override
  String get postActionsBlockDescription => '어떤 커뮤니티에서도 이 사용자의 게시물을 볼 수 없습니다';

  @override
  String postActionsUserBlocked(String name) {
    return '$name을(를) 차단했습니다.';
  }

  @override
  String get postActionsOwnPost => '내 게시물입니다';

  @override
  String get postActionsNoActions => '사용 가능한 관리 작업이 없습니다';

  @override
  String postActionsBlockTitle(String name) {
    return '$name을(를) 차단할까요?';
  }

  @override
  String postActionsBlockBody(String name) {
    return '$name의 게시물을 어떤 커뮤니티에서도 볼 수 없습니다. 알림은 보내지 않습니다.';
  }

  @override
  String get postActionsBlock => '차단';

  @override
  String likedByCount(int count) {
    return '$count명이 좋아함';
  }
}
