// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Momento';

  @override
  String get appTagline => 'すべての瞬間を、美しく共有';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '削除';

  @override
  String get commonRemove => '外す';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonShare => '共有';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonSubmit => '送信';

  @override
  String get commonSomethingWentWrong => '問題が発生しました';

  @override
  String commonFailedWithError(String error) {
    return '失敗: $error';
  }

  @override
  String get commonYouAreOffline => 'オフラインです';

  @override
  String get authYourName => 'お名前';

  @override
  String get authYourNameHint => '名前を入力してください';

  @override
  String get authEmail => 'メールアドレス';

  @override
  String get authEmailHint => '有効なメールアドレスを入力';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authPassword => 'パスワード';

  @override
  String get authPasswordHint => '6文字以上';

  @override
  String get authCreateAccount => 'アカウントを作成';

  @override
  String get authSignIn => 'ログイン';

  @override
  String get authSignOut => 'ログアウト';

  @override
  String get authForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get authContinueWithGoogle => 'Googleで続行';

  @override
  String get authAlreadyHaveAccount => 'アカウントをお持ちですか？ ログイン';

  @override
  String get authNoAccount => 'アカウントがありませんか？ 登録';

  @override
  String get authByCreatingYouAgree => 'アカウントを作成すると、以下に同意したことになります：';

  @override
  String get authBySigningInYouAgree => 'ログインすると、以下に同意したことになります：';

  @override
  String get authTerms => '利用規約';

  @override
  String get authPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get authResetPasswordTitle => 'パスワードをリセット';

  @override
  String get authResetPasswordDescription =>
      'メールアドレスを入力してください。パスワードリセット用のリンクをお送りします。';

  @override
  String get authSend => '送信';

  @override
  String authResetLinkSent(String email) {
    return '$emailにリセットリンクを送信しました';
  }

  @override
  String get verifyTitle => 'メールを確認してください';

  @override
  String verifyDescription(String email) {
    return '$emailに6桁のコードを送信しました。アカウントを確認するために、下に入力してください。';
  }

  @override
  String get verifyCodeSent => 'コードを送信しました — 受信トレイを確認してください。';

  @override
  String get verifyCodeSentNew => '新しいコードを送信しました — 受信トレイを確認してください。';

  @override
  String get verifyCodeFailed => 'コードを送信できませんでした。再送をタップしてもう一度お試しください。';

  @override
  String get verifyCodeFailedNew => '新しいコードを送信できませんでした。再試行してください。';

  @override
  String get verifySomethingWrong => '問題が発生しました。再試行してください。';

  @override
  String verifyResendIn(int seconds) {
    return '$seconds秒後に再送';
  }

  @override
  String get verifyResend => 'コードを再送';

  @override
  String get onboardingWelcomeTitle => 'Momentoへようこそ';

  @override
  String get onboardingWelcomeBody =>
      '身近な人たちとフィルターのない瞬間を共有しましょう。いいねの数も、アルゴリズムもありません — 日々の小さなひとコマだけ。';

  @override
  String get onboardingRoomsTitle => 'コミュニティを作成または参加';

  @override
  String get onboardingRoomsBody =>
      'コミュニティは写真を共有するプライベートな空間です。家族、旅行、友達のグループのために作って、6文字のコードで招待しましょう。';

  @override
  String get onboardingExpireTitle => '写真は6時間で消えます';

  @override
  String get onboardingExpireBody =>
      'すべての写真が自動的に期限切れになります。撮って、共有して、進む — アーカイブもプレッシャーもなし。';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingGetStarted => 'はじめる';

  @override
  String get homeFeed => 'フィード';

  @override
  String get homeRooms => 'コミュニティ';

  @override
  String get homeAccount => 'アカウント';

  @override
  String get homeNewMomento => '新しいMomento';

  @override
  String get homeCouldNotLoadAccount => 'アカウントを読み込めませんでした。';

  @override
  String get homeCouldNotLoadRooms => 'コミュニティを読み込めませんでした。';

  @override
  String get homeCouldNotLoadPosts => '投稿を読み込めませんでした。';

  @override
  String get homeNoRoomsTitle => 'まだコミュニティがありません';

  @override
  String get homeNoRoomsHomeBody => 'コミュニティタブを開いて作成または参加してください。';

  @override
  String get homeNoMomentosTitle => 'まだMomentoがありません';

  @override
  String get homeNoMomentosBody => '写真を撮ってコミュニティに共有しましょう！';

  @override
  String get homeExpired => '期限切れ';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return '残り$hours時間$minutes分';
  }

  @override
  String get roomsMyRooms => 'マイコミュニティ';

  @override
  String get roomsJoinByCode => 'コードで参加';

  @override
  String get roomsCreateRoom => 'コミュニティを作成';

  @override
  String get roomsJoinRoom => 'コミュニティに参加';

  @override
  String get roomsEmptyTitle => 'まだコミュニティがありません';

  @override
  String get roomsEmptyBody => '新しいコミュニティを作成するか、コードで参加してMomentoの共有を始めましょう。';

  @override
  String get roomsCodePrefix => 'コード ';

  @override
  String get roomsFavorite => 'お気に入り';

  @override
  String get roomsUnfavorite => 'お気に入り解除';

  @override
  String get roomsActivate => '有効化';

  @override
  String get roomsDeactivate => '無効化';

  @override
  String get createRoomTitle => 'コミュニティを作成';

  @override
  String get createRoomPhotoLabel => 'コミュニティの写真（任意）';

  @override
  String get createRoomNameLabel => 'コミュニティ名';

  @override
  String get createRoomNameHint => '例：家族、2026年の旅行、親友';

  @override
  String get createRoomNameRequired => 'コミュニティ名を入力してください';

  @override
  String get createRoomWhoCanJoin => '誰が参加できますか？';

  @override
  String get createRoomPublic => '公開';

  @override
  String get createRoomPublicDescription => 'コードを知っている人なら誰でもすぐに参加できます';

  @override
  String get createRoomPermission => '承認制';

  @override
  String get createRoomPermissionDescription => '新メンバーは管理者の承認が必要です';

  @override
  String get joinRoomTitle => 'コミュニティに参加';

  @override
  String get joinRoomHaveCode => 'コードをお持ちですか？';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix => 'コミュニティコードは6文字です';

  @override
  String get joinRoomNotFound => 'そのコードのコミュニティは見つかりませんでした';

  @override
  String joinRoomRequestSent(String name) {
    return 'リクエストを送信しました。\"$name\"の管理者の承認を待っています。';
  }

  @override
  String get joinRoomSearch => 'または公開コミュニティを検索';

  @override
  String get joinRoomSearchHint => 'コミュニティ名…';

  @override
  String get joinRoomNoResults => '一致する公開コミュニティはありません。';

  @override
  String get joinRoomPermissionOnly => '承認制コミュニティはコードでのみ参加できます。';

  @override
  String joinRoomMembers(int count) {
    return '$count人のメンバー';
  }

  @override
  String get joinRoomJoin => '参加';

  @override
  String get roomDetailSettings => 'コミュニティ設定';

  @override
  String get roomDetailMembers => 'メンバー';

  @override
  String get roomDetailCouldNotLoadPosts => '投稿を読み込めませんでした。';

  @override
  String get roomDetailEmptyTitle => 'このコミュニティにはまだMomentoがありません';

  @override
  String get roomDetailEmptyBody => 'カメラから写真を撮って最初の一人になりましょう。';

  @override
  String get roomSettingsTitle => 'コミュニティ設定';

  @override
  String get roomSettingsRename => 'コミュニティ名を変更';

  @override
  String get roomSettingsModeration => 'モデレーション';

  @override
  String get roomSettingsPendingJoinRequests => '保留中の参加リクエスト';

  @override
  String roomSettingsMembersCount(int count) {
    return 'メンバー（$count）';
  }

  @override
  String get roomSettingsLeaveRoom => 'コミュニティを退出';

  @override
  String get roomSettingsDeleteRoom => 'コミュニティを削除';

  @override
  String get roomSettingsPublic => '公開';

  @override
  String get roomSettingsPermission => '承認制';

  @override
  String get roomSettingsRoomCode => 'コミュニティコード';

  @override
  String get roomSettingsCodeCopied => 'コードをコピーしました！';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return 'Momentoで私の\"$name\"コミュニティに参加しよう — コード $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return 'Momentoの$nameに参加';
  }

  @override
  String get roomSettingsRequirePostApproval => '投稿の承認を必須にする';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      '通常メンバーの投稿は管理者の承認を待ちます。管理者と信頼ユーザーは即座に投稿されます。';

  @override
  String get roomSettingsReviewPending => '保留中の投稿を確認';

  @override
  String get roomSettingsNoPending => '保留中のリクエストはありません';

  @override
  String get roomSettingsTrustedTag => '信頼 — 投稿承認をスキップ';

  @override
  String get roomSettingsMakeAdmin => '管理者にする';

  @override
  String get roomSettingsRemoveAdmin => '管理者から外す';

  @override
  String get roomSettingsRemoveTrusted => '信頼ステータスを解除';

  @override
  String get roomSettingsMarkTrusted => '信頼として指定';

  @override
  String get roomSettingsRemoveFromRoom => 'コミュニティから外す';

  @override
  String get roomSettingsRemoveMemberTitle => 'メンバーを外しますか？';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return '$memberは\"$room\"から外されます。';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return '写真の更新に失敗：$error';
  }

  @override
  String get roomSettingsNewName => '新しい名前';

  @override
  String get roomSettingsLeaveTitle => 'コミュニティを退出しますか？';

  @override
  String roomSettingsLeaveBody(String name) {
    return '\"$name\"からのMomentoが届かなくなります。';
  }

  @override
  String get roomSettingsLeave => '退出';

  @override
  String get roomSettingsDeleteTitle => 'コミュニティを削除しますか？';

  @override
  String roomSettingsDeleteBody(String name) {
    return '\"$name\"はすべてのメンバーから完全に削除されます。元に戻せません。';
  }

  @override
  String pendingPostsTitle(String room) {
    return '保留中 — $room';
  }

  @override
  String get pendingPostsEmpty => '承認待ちの項目はありません。';

  @override
  String get pendingPostsReject => '却下';

  @override
  String get pendingPostsApprove => '承認';

  @override
  String get cameraTitle => '新しいMomento';

  @override
  String get cameraNoRooms => 'Momentoを投稿するには、まずコミュニティを作成または参加してください。';

  @override
  String get cameraProcessingVideo => '動画を処理中…';

  @override
  String get cameraMuted => 'ミュート';

  @override
  String get cameraCaptureHint => '写真または6秒のクリップを撮影';

  @override
  String get cameraPhoto => '写真';

  @override
  String get cameraVideo => '動画';

  @override
  String get cameraPhotoFromGallery => 'ギャラリーから写真';

  @override
  String get cameraVideoFromGallery => 'ギャラリーから動画';

  @override
  String get cameraRetake => '撮り直し';

  @override
  String get cameraPostClip => 'クリップを投稿';

  @override
  String get cameraPostMomento => 'Momentoを投稿';

  @override
  String get cameraCaptionHint => 'キャプションを追加（任意）';

  @override
  String get cameraPostTo => '投稿先';

  @override
  String cameraActiveRoomsCount(int count) {
    return 'アクティブなコミュニティ（$count）';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return 'すべてのコミュニティ（$count）';
  }

  @override
  String get cameraPickRooms => '選択…';

  @override
  String get cameraPickAtLeastOne => 'コミュニティを1つ以上選択してください';

  @override
  String cameraPostedTo(int count) {
    return '$count個のコミュニティに投稿しました！';
  }

  @override
  String cameraPendingApproval(int count) {
    return '$count件の投稿が管理者の承認待ちです。';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live件投稿、$pending件承認待ち。';
  }

  @override
  String cameraFailedToSend(String error) {
    return '送信に失敗：$error';
  }

  @override
  String get cameraCouldNotProcessVideo => '動画を処理できませんでした。';

  @override
  String get cameraVideoTooLong => '動画は6秒以下である必要があります。';

  @override
  String get cameraCouldNotPoster => 'ポスターフレームを生成できませんでした。';

  @override
  String get accountTitle => 'マイアカウント';

  @override
  String get accountActiveRooms => 'アクティブなコミュニティ';

  @override
  String get accountActiveRoomsDescription =>
      '投稿はデフォルトでここに送られます。コミュニティタブでオン/オフを切り替えできます。';

  @override
  String get accountFavoriteRooms => 'お気に入りのコミュニティ';

  @override
  String get accountFavoriteRoomsDescription => 'お気に入りはフィードとウィジェットの先頭に表示されます。';

  @override
  String get accountBlockedUsers => 'ブロックしたユーザー';

  @override
  String get accountLegal => '法的情報';

  @override
  String get accountTermsOfService => '利用規約';

  @override
  String get accountPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get accountSignOut => 'ログアウト';

  @override
  String get accountDeleteMy => 'アカウントを削除';

  @override
  String get accountDeleteTitle => 'アカウントを削除しますか？';

  @override
  String get accountDeleteBody =>
      'アカウント、すべてのコミュニティのメンバーシップ、お気に入りが完全に削除されます。投稿は自然に期限切れになります。元に戻せません。';

  @override
  String get accountReauthRequired => 'ログアウトしてから再度ログインし、もう一度削除をお試しください。';

  @override
  String accountFailedWithMessage(String message) {
    return '失敗：$message';
  }

  @override
  String accountRoomsCount(int count) {
    return '$count個のコミュニティ';
  }

  @override
  String get accountEditProfile => 'プロフィールを編集';

  @override
  String accountStreakDays(int count) {
    return '$count日連続';
  }

  @override
  String accountStreakBest(int count) {
    return '最高：$count日';
  }

  @override
  String get accountStreakKeepGoing => '続けましょう — 今日投稿する';

  @override
  String get accountNoBlocked => 'ブロックしたユーザーはいません';

  @override
  String get accountUnblock => 'ブロック解除';

  @override
  String get accountLanguage => '言語';

  @override
  String get accountLanguageSystem => 'システムのデフォルト';

  @override
  String get accountNoActiveRooms => 'アクティブなコミュニティなし';

  @override
  String get accountNoFavorites => 'お気に入りなし';

  @override
  String get roomSettingsCreator => '作成者';

  @override
  String get roomSettingsAdmin => '管理者';

  @override
  String get editProfileTitle => 'プロフィールを編集';

  @override
  String get editProfileTapPhoto => '写真を変更するにはタップ';

  @override
  String get editProfileDisplayName => '表示名';

  @override
  String get editProfileNameRequired => '名前は空にできません';

  @override
  String editProfileFailedSave(String error) {
    return '保存に失敗：$error';
  }

  @override
  String get postActionsReportTitle => 'この投稿を通報';

  @override
  String get postActionsReportPrompt => 'なぜこの投稿を通報しますか？';

  @override
  String get postActionsReportPlaceholder => '任意 — 何が問題か説明してください';

  @override
  String get postActionsReportSubmitted => '通報を送信しました。ありがとうございます。';

  @override
  String postActionsBlockUser(String name) {
    return '$nameをブロック';
  }

  @override
  String get postActionsBlockDescription => 'どのコミュニティでもこのユーザーの投稿は表示されません';

  @override
  String postActionsUserBlocked(String name) {
    return '$nameをブロックしました。';
  }

  @override
  String get postActionsOwnPost => 'これはあなた自身の投稿です';

  @override
  String get postActionsNoActions => '利用可能なモデレーション操作はありません';

  @override
  String postActionsBlockTitle(String name) {
    return '$nameをブロックしますか？';
  }

  @override
  String postActionsBlockBody(String name) {
    return '$nameの投稿はどのコミュニティでも表示されなくなります。通知は送られません。';
  }

  @override
  String get postActionsBlock => 'ブロック';

  @override
  String likedByCount(int count) {
    return '$count人がいいね';
  }
}
