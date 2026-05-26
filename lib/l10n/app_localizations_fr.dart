// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Momento';

  @override
  String get appTagline => 'Chaque instant, partagé avec élégance';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonSubmit => 'Envoyer';

  @override
  String get commonSomethingWentWrong => 'Une erreur est survenue';

  @override
  String commonFailedWithError(String error) {
    return 'Échec : $error';
  }

  @override
  String get commonYouAreOffline => 'Vous êtes hors ligne';

  @override
  String get authYourName => 'Votre nom';

  @override
  String get authYourNameHint => 'Saisissez votre nom';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authEmailHint => 'Saisissez un e-mail valide';

  @override
  String get authEmailPlaceholder => 'vous@exemple.com';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authPasswordHint => '6 caractères minimum';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authContinueWithGoogle => 'Continuer avec Google';

  @override
  String get authAlreadyHaveAccount =>
      'Vous avez déjà un compte ? Se connecter';

  @override
  String get authNoAccount => 'Pas encore de compte ? S\'inscrire';

  @override
  String get authByCreatingYouAgree =>
      'En créant un compte, vous acceptez nos ';

  @override
  String get authBySigningInYouAgree =>
      'En vous connectant, vous acceptez nos ';

  @override
  String get authTerms => 'Conditions';

  @override
  String get authPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get authResetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get authResetPasswordDescription =>
      'Saisissez votre e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get authSend => 'Envoyer';

  @override
  String authResetLinkSent(String email) {
    return 'Lien de réinitialisation envoyé à $email';
  }

  @override
  String get verifyTitle => 'Vérifiez votre e-mail';

  @override
  String verifyDescription(String email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email. Saisissez-le ci-dessous pour confirmer votre compte.';
  }

  @override
  String get verifyCodeSent =>
      'Code envoyé — vérifiez votre boîte de réception.';

  @override
  String get verifyCodeSentNew =>
      'Nouveau code envoyé — vérifiez votre boîte de réception.';

  @override
  String get verifyCodeFailed =>
      'Impossible d\'envoyer un code. Appuyez sur renvoyer pour réessayer.';

  @override
  String get verifyCodeFailedNew =>
      'Impossible d\'envoyer un nouveau code. Réessayez.';

  @override
  String get verifySomethingWrong => 'Une erreur est survenue. Réessayez.';

  @override
  String verifyResendIn(int seconds) {
    return 'Renvoyer le code dans $seconds s';
  }

  @override
  String get verifyResend => 'Renvoyer le code';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue sur Momento';

  @override
  String get onboardingWelcomeBody =>
      'Partagez des moments authentiques avec vos proches. Pas de likes, pas d\'algorithme — juste de petits aperçus de votre journée.';

  @override
  String get onboardingRoomsTitle => 'Créez ou rejoignez des communautés';

  @override
  String get onboardingRoomsBody =>
      'Une communauté est un espace privé pour partager des photos. Créez-en une pour votre famille, votre voyage, votre groupe d\'amis — et invitez avec un code de 6 caractères.';

  @override
  String get onboardingExpireTitle => 'Les photos disparaissent en 6 heures';

  @override
  String get onboardingExpireBody =>
      'Chaque photo expire automatiquement. Capturez, partagez, et passez à autre chose — pas d\'archive, pas de pression.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get homeFeed => 'Fil';

  @override
  String get homeRooms => 'Communautés';

  @override
  String get homeAccount => 'Compte';

  @override
  String get homeNewMomento => 'Nouveau Momento';

  @override
  String get homeCouldNotLoadAccount => 'Impossible de charger votre compte.';

  @override
  String get homeCouldNotLoadRooms => 'Impossible de charger vos communautés.';

  @override
  String get homeCouldNotLoadPosts => 'Impossible de charger les publications.';

  @override
  String get homeNoRoomsTitle => 'Aucune communauté';

  @override
  String get homeNoRoomsHomeBody =>
      'Ouvrez l\'onglet Communautés pour en créer ou en rejoindre une.';

  @override
  String get homeNoMomentosTitle => 'Aucun momento';

  @override
  String get homeNoMomentosBody =>
      'Prenez une photo et partagez-la avec vos communautés !';

  @override
  String get homeExpired => 'Expiré';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return '$hours h $minutes min restantes';
  }

  @override
  String get roomsMyRooms => 'Mes communautés';

  @override
  String get roomsJoinByCode => 'Rejoindre avec un code';

  @override
  String get roomsCreateRoom => 'Créer une communauté';

  @override
  String get roomsJoinRoom => 'Rejoindre une communauté';

  @override
  String get roomsEmptyTitle => 'Aucune communauté';

  @override
  String get roomsEmptyBody =>
      'Créez une nouvelle communauté ou rejoignez-en une avec un code pour commencer à partager des momentos.';

  @override
  String get roomsCodePrefix => 'Code ';

  @override
  String get roomsFavorite => 'Favori';

  @override
  String get roomsUnfavorite => 'Retirer des favoris';

  @override
  String get roomsActivate => 'Activer';

  @override
  String get roomsDeactivate => 'Désactiver';

  @override
  String get createRoomTitle => 'Créer une communauté';

  @override
  String get createRoomPhotoLabel => 'Photo de la communauté (facultatif)';

  @override
  String get createRoomNameLabel => 'Nom de la communauté';

  @override
  String get createRoomNameHint => 'ex. Famille, Voyage 2026, Meilleurs amis';

  @override
  String get createRoomNameRequired => 'Veuillez saisir un nom de communauté';

  @override
  String get createRoomWhoCanJoin => 'Qui peut rejoindre ?';

  @override
  String get createRoomPublic => 'Publique';

  @override
  String get createRoomPublicDescription =>
      'Toute personne ayant le code peut rejoindre instantanément';

  @override
  String get createRoomPermission => 'Sur invitation';

  @override
  String get createRoomPermissionDescription =>
      'Les nouveaux membres doivent être approuvés par un admin';

  @override
  String get joinRoomTitle => 'Rejoindre une communauté';

  @override
  String get joinRoomHaveCode => 'Vous avez un code ?';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix =>
      'Les codes de communauté font 6 caractères';

  @override
  String get joinRoomNotFound => 'Aucune communauté avec ce code';

  @override
  String joinRoomRequestSent(String name) {
    return 'Demande envoyée. En attente de l\'approbation d\'un admin de \"$name\".';
  }

  @override
  String get joinRoomSearch => 'Ou rechercher des communautés publiques';

  @override
  String get joinRoomSearchHint => 'Nom de la communauté…';

  @override
  String get joinRoomNoResults => 'Aucune communauté publique correspondante.';

  @override
  String get joinRoomPermissionOnly =>
      'Les communautés sur invitation ne peuvent être rejointes qu\'avec leur code.';

  @override
  String joinRoomMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get joinRoomJoin => 'Rejoindre';

  @override
  String get roomDetailSettings => 'Paramètres de la communauté';

  @override
  String get roomDetailMembers => 'Membres';

  @override
  String get roomDetailCouldNotLoadPosts =>
      'Impossible de charger les publications.';

  @override
  String get roomDetailEmptyTitle => 'Aucun momento dans cette communauté';

  @override
  String get roomDetailEmptyBody =>
      'Prenez une photo depuis l\'appareil photo pour être le premier.';

  @override
  String get roomSettingsTitle => 'Paramètres de la communauté';

  @override
  String get roomSettingsRename => 'Renommer la communauté';

  @override
  String get roomSettingsModeration => 'Modération';

  @override
  String get roomSettingsPendingJoinRequests =>
      'Demandes d\'adhésion en attente';

  @override
  String roomSettingsMembersCount(int count) {
    return 'Membres ($count)';
  }

  @override
  String get roomSettingsLeaveRoom => 'Quitter la communauté';

  @override
  String get roomSettingsDeleteRoom => 'Supprimer la communauté';

  @override
  String get roomSettingsPublic => 'Publique';

  @override
  String get roomSettingsPermission => 'Sur invitation';

  @override
  String get roomSettingsRoomCode => 'Code de la communauté';

  @override
  String get roomSettingsCodeCopied => 'Code copié !';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return 'Rejoins ma communauté \"$name\" sur Momento — utilise le code $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return 'Rejoindre $name sur Momento';
  }

  @override
  String get roomSettingsRequirePostApproval =>
      'Exiger l\'approbation des publications';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      'Les publications des membres réguliers attendent l\'approbation d\'un admin. Les admins et les utilisateurs de confiance publient immédiatement.';

  @override
  String get roomSettingsReviewPending =>
      'Examiner les publications en attente';

  @override
  String get roomSettingsNoPending => 'Aucune demande en attente';

  @override
  String get roomSettingsTrustedTag =>
      'De confiance — contourne l\'approbation';

  @override
  String get roomSettingsMakeAdmin => 'Nommer admin';

  @override
  String get roomSettingsRemoveAdmin => 'Retirer admin';

  @override
  String get roomSettingsRemoveTrusted => 'Retirer la confiance';

  @override
  String get roomSettingsMarkTrusted => 'Marquer comme de confiance';

  @override
  String get roomSettingsRemoveFromRoom => 'Retirer de la communauté';

  @override
  String get roomSettingsRemoveMemberTitle => 'Retirer le membre ?';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return '$member sera retiré de \"$room\".';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return 'Échec de la mise à jour de la photo : $error';
  }

  @override
  String get roomSettingsNewName => 'Nouveau nom';

  @override
  String get roomSettingsLeaveTitle => 'Quitter la communauté ?';

  @override
  String roomSettingsLeaveBody(String name) {
    return 'Vous ne recevrez plus de momentos de \"$name\".';
  }

  @override
  String get roomSettingsLeave => 'Quitter';

  @override
  String get roomSettingsDeleteTitle => 'Supprimer la communauté ?';

  @override
  String roomSettingsDeleteBody(String name) {
    return '\"$name\" sera définitivement supprimée pour tous les membres. Action irréversible.';
  }

  @override
  String pendingPostsTitle(String room) {
    return 'En attente — $room';
  }

  @override
  String get pendingPostsEmpty => 'Rien en attente d\'approbation.';

  @override
  String get pendingPostsReject => 'Rejeter';

  @override
  String get pendingPostsApprove => 'Approuver';

  @override
  String get cameraTitle => 'Nouveau Momento';

  @override
  String get cameraNoRooms =>
      'Rejoignez ou créez une communauté avant de publier des momentos.';

  @override
  String get cameraProcessingVideo => 'Traitement de la vidéo…';

  @override
  String get cameraMuted => 'Muet';

  @override
  String get cameraCaptureHint => 'Prenez une photo ou un clip de 6 secondes';

  @override
  String get cameraPhoto => 'Photo';

  @override
  String get cameraVideo => 'Vidéo';

  @override
  String get cameraPhotoFromGallery => 'Photo depuis la galerie';

  @override
  String get cameraVideoFromGallery => 'Vidéo depuis la galerie';

  @override
  String get cameraRetake => 'Reprendre';

  @override
  String get cameraPostClip => 'Publier le clip';

  @override
  String get cameraPostMomento => 'Publier le Momento';

  @override
  String get cameraCaptionHint => 'Ajouter une légende (facultatif)';

  @override
  String get cameraPostTo => 'Publier dans';

  @override
  String cameraActiveRoomsCount(int count) {
    return 'Communautés actives ($count)';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return 'Toutes les communautés ($count)';
  }

  @override
  String get cameraPickRooms => 'Choisir…';

  @override
  String get cameraPickAtLeastOne => 'Choisissez au moins une communauté';

  @override
  String cameraPostedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Publié dans $count communautés !',
      one: 'Publié dans 1 communauté !',
    );
    return '$_temp0';
  }

  @override
  String cameraPendingApproval(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publications en attente d\'approbation.',
      one: '1 publication en attente d\'approbation.',
    );
    return '$_temp0';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live en ligne, $pending en attente d\'approbation.';
  }

  @override
  String cameraFailedToSend(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String get cameraCouldNotProcessVideo => 'Impossible de traiter la vidéo.';

  @override
  String get cameraVideoTooLong => 'La vidéo doit durer 6 secondes ou moins.';

  @override
  String get cameraCouldNotPoster =>
      'Impossible de générer l\'image de couverture.';

  @override
  String get accountTitle => 'Mon compte';

  @override
  String get accountActiveRooms => 'Communautés actives';

  @override
  String get accountActiveRoomsDescription =>
      'Les publications vont ici par défaut. Activez/désactivez dans l\'onglet Communautés.';

  @override
  String get accountFavoriteRooms => 'Communautés favorites';

  @override
  String get accountFavoriteRoomsDescription =>
      'Les favoris remontent en tête du fil et de la rotation du widget.';

  @override
  String get accountBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get accountLegal => 'Mentions légales';

  @override
  String get accountTermsOfService => 'Conditions d\'utilisation';

  @override
  String get accountPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get accountDeleteMy => 'Supprimer mon compte';

  @override
  String get accountDeleteTitle => 'Supprimer votre compte ?';

  @override
  String get accountDeleteBody =>
      'Cela supprimera définitivement votre compte, vos adhésions à toutes les communautés et vos favoris. Les publications expireront naturellement. Action irréversible.';

  @override
  String get accountReauthRequired =>
      'Veuillez vous déconnecter et vous reconnecter, puis réessayer la suppression.';

  @override
  String accountFailedWithMessage(String message) {
    return 'Échec : $message';
  }

  @override
  String accountRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count communautés',
      one: '1 communauté',
    );
    return '$_temp0';
  }

  @override
  String get accountEditProfile => 'Modifier le profil';

  @override
  String accountStreakDays(int count) {
    return 'Série de $count jours';
  }

  @override
  String accountStreakBest(int count) {
    return 'Record : $count jours';
  }

  @override
  String get accountStreakKeepGoing => 'Continuez — publiez aujourd\'hui';

  @override
  String get accountNoBlocked => 'Aucun utilisateur bloqué';

  @override
  String get accountUnblock => 'Débloquer';

  @override
  String get accountLanguage => 'Langue';

  @override
  String get accountLanguageSystem => 'Langue du système';

  @override
  String get accountNoActiveRooms => 'Aucune communauté active';

  @override
  String get accountNoFavorites => 'Aucun favori';

  @override
  String get roomSettingsCreator => 'Créateur';

  @override
  String get roomSettingsAdmin => 'Admin';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get editProfileTapPhoto => 'Appuyez pour changer la photo';

  @override
  String get editProfileDisplayName => 'Nom affiché';

  @override
  String get editProfileNameRequired => 'Le nom ne peut pas être vide';

  @override
  String editProfileFailedSave(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get postActionsReportTitle => 'Signaler cette publication';

  @override
  String get postActionsReportPrompt =>
      'Pourquoi signalez-vous cette publication ?';

  @override
  String get postActionsReportPlaceholder =>
      'Facultatif — décrivez le problème';

  @override
  String get postActionsReportSubmitted => 'Signalement envoyé. Merci.';

  @override
  String postActionsBlockUser(String name) {
    return 'Bloquer $name';
  }

  @override
  String get postActionsBlockDescription =>
      'Vous ne verrez plus ses publications dans aucune communauté';

  @override
  String postActionsUserBlocked(String name) {
    return '$name bloqué.';
  }

  @override
  String get postActionsOwnPost => 'C\'est votre propre publication';

  @override
  String get postActionsNoActions => 'Aucune action de modération disponible';

  @override
  String postActionsBlockTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String postActionsBlockBody(String name) {
    return 'Vous ne verrez plus les publications de $name dans aucune communauté. La personne ne sera pas notifiée.';
  }

  @override
  String get postActionsBlock => 'Bloquer';

  @override
  String likedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aimé par $count personnes',
      one: 'Aimé par 1 personne',
    );
    return '$_temp0';
  }
}
