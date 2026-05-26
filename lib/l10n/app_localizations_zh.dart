// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Momento';

  @override
  String get appTagline => '每个瞬间，优雅分享';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonRemove => '移除';

  @override
  String get commonCopy => '复制';

  @override
  String get commonShare => '分享';

  @override
  String get commonRetry => '重试';

  @override
  String get commonSubmit => '提交';

  @override
  String get commonSomethingWentWrong => '出错了';

  @override
  String commonFailedWithError(String error) {
    return '失败：$error';
  }

  @override
  String get commonYouAreOffline => '您已离线';

  @override
  String get authYourName => '您的名字';

  @override
  String get authYourNameHint => '输入您的名字';

  @override
  String get authEmail => '电子邮箱';

  @override
  String get authEmailHint => '输入有效的电子邮箱';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '至少6个字符';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authSignIn => '登录';

  @override
  String get authSignOut => '退出登录';

  @override
  String get authForgotPassword => '忘记密码？';

  @override
  String get authContinueWithGoogle => '使用 Google 继续';

  @override
  String get authAlreadyHaveAccount => '已有账户？登录';

  @override
  String get authNoAccount => '还没有账户？注册';

  @override
  String get authByCreatingYouAgree => '创建账户即表示您同意我们的';

  @override
  String get authBySigningInYouAgree => '登录即表示您同意我们的';

  @override
  String get authTerms => '条款';

  @override
  String get authPrivacyPolicy => '隐私政策';

  @override
  String get authResetPasswordTitle => '重置密码';

  @override
  String get authResetPasswordDescription => '输入您的电子邮箱，我们将发送重置密码的链接。';

  @override
  String get authSend => '发送';

  @override
  String authResetLinkSent(String email) {
    return '已将重置链接发送至 $email';
  }

  @override
  String get verifyTitle => '请查收您的邮件';

  @override
  String verifyDescription(String email) {
    return '我们已向 $email 发送了6位验证码。请在下方输入以确认您的账户。';
  }

  @override
  String get verifyCodeSent => '已发送验证码 — 请查看收件箱。';

  @override
  String get verifyCodeSentNew => '已发送新验证码 — 请查看收件箱。';

  @override
  String get verifyCodeFailed => '无法发送验证码。点击重新发送以重试。';

  @override
  String get verifyCodeFailedNew => '无法发送新验证码。请重试。';

  @override
  String get verifySomethingWrong => '出错了。请重试。';

  @override
  String verifyResendIn(int seconds) {
    return '$seconds 秒后可重新发送';
  }

  @override
  String get verifyResend => '重新发送验证码';

  @override
  String get onboardingWelcomeTitle => '欢迎来到 Momento';

  @override
  String get onboardingWelcomeBody => '和最亲近的人分享真实的瞬间。没有点赞数，没有算法 — 只有日常的小片段。';

  @override
  String get onboardingRoomsTitle => '创建或加入社群';

  @override
  String get onboardingRoomsBody =>
      '社群是分享照片的私密空间。为您的家人、旅行、朋友圈创建一个 — 用6位代码邀请他人。';

  @override
  String get onboardingExpireTitle => '照片6小时后消失';

  @override
  String get onboardingExpireBody => '每张照片都会自动过期。拍下、分享、然后继续 — 没有存档，没有压力。';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingGetStarted => '开始';

  @override
  String get homeFeed => '动态';

  @override
  String get homeRooms => '社群';

  @override
  String get homeAccount => '账户';

  @override
  String get homeNewMomento => '新 Momento';

  @override
  String get homeCouldNotLoadAccount => '无法加载您的账户。';

  @override
  String get homeCouldNotLoadRooms => '无法加载您的社群。';

  @override
  String get homeCouldNotLoadPosts => '无法加载帖子。';

  @override
  String get homeNoRoomsTitle => '还没有社群';

  @override
  String get homeNoRoomsHomeBody => '打开社群标签来创建或加入。';

  @override
  String get homeNoMomentosTitle => '还没有 Momento';

  @override
  String get homeNoMomentosBody => '拍张照片，分享给您的社群！';

  @override
  String get homeExpired => '已过期';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return '剩余 $hours小时$minutes分';
  }

  @override
  String get roomsMyRooms => '我的社群';

  @override
  String get roomsJoinByCode => '用代码加入';

  @override
  String get roomsCreateRoom => '创建社群';

  @override
  String get roomsJoinRoom => '加入社群';

  @override
  String get roomsEmptyTitle => '还没有社群';

  @override
  String get roomsEmptyBody => '创建新社群或用代码加入一个社群，开始分享您的瞬间。';

  @override
  String get roomsCodePrefix => '代码 ';

  @override
  String get roomsFavorite => '收藏';

  @override
  String get roomsUnfavorite => '取消收藏';

  @override
  String get roomsActivate => '激活';

  @override
  String get roomsDeactivate => '停用';

  @override
  String get createRoomTitle => '创建社群';

  @override
  String get createRoomPhotoLabel => '社群照片（可选）';

  @override
  String get createRoomNameLabel => '社群名称';

  @override
  String get createRoomNameHint => '如：家人、2026 旅行、好朋友';

  @override
  String get createRoomNameRequired => '请输入社群名称';

  @override
  String get createRoomWhoCanJoin => '谁可以加入？';

  @override
  String get createRoomPublic => '公开';

  @override
  String get createRoomPublicDescription => '拥有社群代码的人可以立即加入';

  @override
  String get createRoomPermission => '需审批';

  @override
  String get createRoomPermissionDescription => '新成员必须由管理员批准';

  @override
  String get joinRoomTitle => '加入社群';

  @override
  String get joinRoomHaveCode => '有代码吗？';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix => '社群代码为6个字符';

  @override
  String get joinRoomNotFound => '找不到该代码对应的社群';

  @override
  String joinRoomRequestSent(String name) {
    return '已发送请求。等待 \"$name\" 的管理员批准。';
  }

  @override
  String get joinRoomSearch => '或搜索公开社群';

  @override
  String get joinRoomSearchHint => '社群名称…';

  @override
  String get joinRoomNoResults => '没有匹配的公开社群。';

  @override
  String get joinRoomPermissionOnly => '需审批的社群只能通过代码加入。';

  @override
  String joinRoomMembers(int count) {
    return '$count 名成员';
  }

  @override
  String get joinRoomJoin => '加入';

  @override
  String get roomDetailSettings => '社群设置';

  @override
  String get roomDetailMembers => '成员';

  @override
  String get roomDetailCouldNotLoadPosts => '无法加载帖子。';

  @override
  String get roomDetailEmptyTitle => '这个社群还没有 Momento';

  @override
  String get roomDetailEmptyBody => '用相机拍张照片成为第一个吧。';

  @override
  String get roomSettingsTitle => '社群设置';

  @override
  String get roomSettingsRename => '重命名社群';

  @override
  String get roomSettingsModeration => '管理';

  @override
  String get roomSettingsPendingJoinRequests => '待处理的加入请求';

  @override
  String roomSettingsMembersCount(int count) {
    return '成员（$count）';
  }

  @override
  String get roomSettingsLeaveRoom => '离开社群';

  @override
  String get roomSettingsDeleteRoom => '删除社群';

  @override
  String get roomSettingsPublic => '公开';

  @override
  String get roomSettingsPermission => '需审批';

  @override
  String get roomSettingsRoomCode => '社群代码';

  @override
  String get roomSettingsCodeCopied => '代码已复制！';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return '加入我在 Momento 的 \"$name\" 社群 — 使用代码 $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return '加入 Momento 的 $name';
  }

  @override
  String get roomSettingsRequirePostApproval => '需要审批帖子';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      '普通成员的帖子需要管理员审批。管理员和受信任的用户可以立即发布。';

  @override
  String get roomSettingsReviewPending => '审核待处理的帖子';

  @override
  String get roomSettingsNoPending => '没有待处理的请求';

  @override
  String get roomSettingsTrustedTag => '受信任 — 跳过帖子审批';

  @override
  String get roomSettingsMakeAdmin => '设为管理员';

  @override
  String get roomSettingsRemoveAdmin => '取消管理员';

  @override
  String get roomSettingsRemoveTrusted => '取消受信任状态';

  @override
  String get roomSettingsMarkTrusted => '标记为受信任';

  @override
  String get roomSettingsRemoveFromRoom => '从社群中移除';

  @override
  String get roomSettingsRemoveMemberTitle => '移除成员？';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return '$member 将从 \"$room\" 中移除。';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return '更新照片失败：$error';
  }

  @override
  String get roomSettingsNewName => '新名称';

  @override
  String get roomSettingsLeaveTitle => '离开社群？';

  @override
  String roomSettingsLeaveBody(String name) {
    return '您将不再收到 \"$name\" 的 Momento。';
  }

  @override
  String get roomSettingsLeave => '离开';

  @override
  String get roomSettingsDeleteTitle => '删除社群？';

  @override
  String roomSettingsDeleteBody(String name) {
    return '\"$name\" 将对所有成员永久删除。此操作无法撤销。';
  }

  @override
  String pendingPostsTitle(String room) {
    return '待处理 — $room';
  }

  @override
  String get pendingPostsEmpty => '没有等待审批的内容。';

  @override
  String get pendingPostsReject => '拒绝';

  @override
  String get pendingPostsApprove => '批准';

  @override
  String get cameraTitle => '新 Momento';

  @override
  String get cameraNoRooms => '请先加入或创建社群，再发布 Momento。';

  @override
  String get cameraProcessingVideo => '正在处理视频…';

  @override
  String get cameraMuted => '静音';

  @override
  String get cameraCaptureHint => '拍摄一张照片或6秒视频';

  @override
  String get cameraPhoto => '照片';

  @override
  String get cameraVideo => '视频';

  @override
  String get cameraPhotoFromGallery => '从相册选择照片';

  @override
  String get cameraVideoFromGallery => '从相册选择视频';

  @override
  String get cameraRetake => '重拍';

  @override
  String get cameraPostClip => '发布视频';

  @override
  String get cameraPostMomento => '发布 Momento';

  @override
  String get cameraCaptionHint => '添加标题（可选）';

  @override
  String get cameraPostTo => '发布到';

  @override
  String cameraActiveRoomsCount(int count) {
    return '活跃社群（$count）';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return '所有社群（$count）';
  }

  @override
  String get cameraPickRooms => '选择…';

  @override
  String get cameraPickAtLeastOne => '请至少选择一个社群';

  @override
  String cameraPostedTo(int count) {
    return '已发布到 $count 个社群！';
  }

  @override
  String cameraPendingApproval(int count) {
    return '$count 个帖子等待管理员审批。';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live 已发布，$pending 等待审批。';
  }

  @override
  String cameraFailedToSend(String error) {
    return '发送失败：$error';
  }

  @override
  String get cameraCouldNotProcessVideo => '无法处理视频。';

  @override
  String get cameraVideoTooLong => '视频必须为6秒或更短。';

  @override
  String get cameraCouldNotPoster => '无法生成封面图。';

  @override
  String get accountTitle => '我的账户';

  @override
  String get accountActiveRooms => '活跃社群';

  @override
  String get accountActiveRoomsDescription => '默认情况下，帖子会发到这里。在社群标签中开关。';

  @override
  String get accountFavoriteRooms => '收藏的社群';

  @override
  String get accountFavoriteRoomsDescription => '收藏会浮到动态和小组件轮播的最前面。';

  @override
  String get accountBlockedUsers => '已屏蔽的用户';

  @override
  String get accountLegal => '法律';

  @override
  String get accountTermsOfService => '服务条款';

  @override
  String get accountPrivacyPolicy => '隐私政策';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get accountDeleteMy => '删除我的账户';

  @override
  String get accountDeleteTitle => '删除您的账户？';

  @override
  String get accountDeleteBody => '这将永久删除您的账户、所有社群的成员资格和收藏。帖子将自然过期。此操作无法撤销。';

  @override
  String get accountReauthRequired => '请退出登录并重新登录，然后再次尝试删除。';

  @override
  String accountFailedWithMessage(String message) {
    return '失败：$message';
  }

  @override
  String accountRoomsCount(int count) {
    return '$count 个社群';
  }

  @override
  String get accountEditProfile => '编辑资料';

  @override
  String accountStreakDays(int count) {
    return '$count 天连击';
  }

  @override
  String accountStreakBest(int count) {
    return '最佳：$count 天';
  }

  @override
  String get accountStreakKeepGoing => '保持势头 — 今天发布';

  @override
  String get accountNoBlocked => '没有已屏蔽的用户';

  @override
  String get accountUnblock => '取消屏蔽';

  @override
  String get accountLanguage => '语言';

  @override
  String get accountLanguageSystem => '跟随系统';

  @override
  String get accountNoActiveRooms => '没有活跃社群';

  @override
  String get accountNoFavorites => '没有收藏';

  @override
  String get roomSettingsCreator => '创建者';

  @override
  String get roomSettingsAdmin => '管理员';

  @override
  String get editProfileTitle => '编辑资料';

  @override
  String get editProfileTapPhoto => '点击更换照片';

  @override
  String get editProfileDisplayName => '显示名称';

  @override
  String get editProfileNameRequired => '名称不能为空';

  @override
  String editProfileFailedSave(String error) {
    return '保存失败：$error';
  }

  @override
  String get postActionsReportTitle => '举报此帖子';

  @override
  String get postActionsReportPrompt => '您为何举报此帖子？';

  @override
  String get postActionsReportPlaceholder => '可选 — 描述哪里有问题';

  @override
  String get postActionsReportSubmitted => '举报已提交，谢谢。';

  @override
  String postActionsBlockUser(String name) {
    return '屏蔽 $name';
  }

  @override
  String get postActionsBlockDescription => '您将不会在任何社群看到他们的帖子';

  @override
  String postActionsUserBlocked(String name) {
    return '已屏蔽 $name。';
  }

  @override
  String get postActionsOwnPost => '这是您自己的帖子';

  @override
  String get postActionsNoActions => '没有可用的管理操作';

  @override
  String postActionsBlockTitle(String name) {
    return '屏蔽 $name？';
  }

  @override
  String postActionsBlockBody(String name) {
    return '您将不会在任何社群看到 $name 的帖子。对方不会被通知。';
  }

  @override
  String get postActionsBlock => '屏蔽';

  @override
  String likedByCount(int count) {
    return '$count 人点赞';
  }
}
