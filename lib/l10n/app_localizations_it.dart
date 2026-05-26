// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Huddlex';

  @override
  String get appTagline => 'Ogni huddle, condiviso con stile';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonRemove => 'Rimuovi';

  @override
  String get commonCopy => 'Copia';

  @override
  String get commonShare => 'Condividi';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonSubmit => 'Invia';

  @override
  String get commonSomethingWentWrong => 'Qualcosa è andato storto';

  @override
  String commonFailedWithError(String error) {
    return 'Errore: $error';
  }

  @override
  String get commonYouAreOffline => 'Sei offline';

  @override
  String get authYourName => 'Il tuo nome';

  @override
  String get authYourNameHint => 'Inserisci il tuo nome';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authEmailHint => 'Inserisci un\'e-mail valida';

  @override
  String get authEmailPlaceholder => 'tu@esempio.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Almeno 6 caratteri';

  @override
  String get authCreateAccount => 'Crea account';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authSignOut => 'Esci';

  @override
  String get authForgotPassword => 'Password dimenticata?';

  @override
  String get authContinueWithGoogle => 'Continua con Google';

  @override
  String get authAlreadyHaveAccount => 'Hai già un account? Accedi';

  @override
  String get authNoAccount => 'Non hai un account? Registrati';

  @override
  String get authByCreatingYouAgree => 'Creando un account accetti i nostri ';

  @override
  String get authBySigningInYouAgree => 'Accedendo accetti i nostri ';

  @override
  String get authTerms => 'Termini';

  @override
  String get authPrivacyPolicy => 'Informativa sulla Privacy';

  @override
  String get authResetPasswordTitle => 'Reimposta password';

  @override
  String get authResetPasswordDescription =>
      'Inserisci la tua e-mail e ti invieremo un link per reimpostare la password.';

  @override
  String get authSend => 'Invia';

  @override
  String authResetLinkSent(String email) {
    return 'Link di reimpostazione inviato a $email';
  }

  @override
  String get verifyTitle => 'Controlla la tua e-mail';

  @override
  String verifyDescription(String email) {
    return 'Abbiamo inviato un codice a 6 cifre a $email. Inseriscilo qui sotto per confermare il tuo account.';
  }

  @override
  String get verifyCodeSent => 'Codice inviato — controlla la tua casella.';

  @override
  String get verifyCodeSentNew =>
      'Nuovo codice inviato — controlla la tua casella.';

  @override
  String get verifyCodeFailed =>
      'Impossibile inviare il codice. Tocca rinvia per riprovare.';

  @override
  String get verifyCodeFailedNew =>
      'Impossibile inviare un nuovo codice. Riprova.';

  @override
  String get verifySomethingWrong => 'Qualcosa è andato storto. Riprova.';

  @override
  String verifyResendIn(int seconds) {
    return 'Rinvia il codice tra $seconds s';
  }

  @override
  String get verifyResend => 'Rinvia il codice';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto su Huddlex';

  @override
  String get onboardingWelcomeBody =>
      'Condividi momenti senza filtri con le persone più vicine. Niente conteggio dei like, niente algoritmi — solo piccoli scorci della tua giornata.';

  @override
  String get onboardingRoomsTitle => 'Crea o unisciti alle Comunità';

  @override
  String get onboardingRoomsBody =>
      'Una Comunità è uno spazio privato per condividere foto. Creane una per la tua famiglia, il tuo viaggio, il tuo gruppo di amici — e invita con un codice di 6 caratteri.';

  @override
  String get onboardingExpireTitle => 'Le foto spariscono in 6 ore';

  @override
  String get onboardingExpireBody =>
      'Ogni foto scade automaticamente. Scatta, condividi e vai avanti — nessun archivio, nessuna pressione.';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingGetStarted => 'Inizia';

  @override
  String get homeFeed => 'Feed';

  @override
  String get homeRooms => 'Comunità';

  @override
  String get homeAccount => 'Account';

  @override
  String get homeNewMomento => 'Nuovo Huddle';

  @override
  String get homeCouldNotLoadAccount => 'Impossibile caricare il tuo account.';

  @override
  String get homeCouldNotLoadRooms => 'Impossibile caricare le tue comunità.';

  @override
  String get homeCouldNotLoadPosts => 'Impossibile caricare i post.';

  @override
  String get homeNoRoomsTitle => 'Nessuna comunità';

  @override
  String get homeNoRoomsHomeBody =>
      'Apri la scheda Comunità per crearne o unirti a una.';

  @override
  String get homeNoMomentosTitle => 'Nessun huddle';

  @override
  String get homeNoMomentosBody =>
      'Scatta una foto e condividila con le tue comunità!';

  @override
  String get homeExpired => 'Scaduto';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return '$hours h $minutes min rimanenti';
  }

  @override
  String get roomsMyRooms => 'Le mie comunità';

  @override
  String get roomsJoinByCode => 'Unisciti con codice';

  @override
  String get roomsCreateRoom => 'Crea Comunità';

  @override
  String get roomsJoinRoom => 'Unisciti a Comunità';

  @override
  String get roomsEmptyTitle => 'Nessuna comunità';

  @override
  String get roomsEmptyBody =>
      'Crea una nuova comunità o unisciti a una con un codice per iniziare a condividere momenti.';

  @override
  String get roomsCodePrefix => 'Codice ';

  @override
  String get roomsFavorite => 'Preferito';

  @override
  String get roomsUnfavorite => 'Rimuovi dai preferiti';

  @override
  String get roomsActivate => 'Attiva';

  @override
  String get roomsDeactivate => 'Disattiva';

  @override
  String get createRoomTitle => 'Crea Comunità';

  @override
  String get createRoomPhotoLabel => 'Foto della comunità (opzionale)';

  @override
  String get createRoomNameLabel => 'Nome della comunità';

  @override
  String get createRoomNameHint => 'es. Famiglia, Viaggio 2026, Migliori amici';

  @override
  String get createRoomNameRequired => 'Inserisci un nome per la comunità';

  @override
  String get createRoomWhoCanJoin => 'Chi può unirsi?';

  @override
  String get createRoomPublic => 'Pubblica';

  @override
  String get createRoomPublicDescription =>
      'Chiunque abbia il codice può unirsi all\'istante';

  @override
  String get createRoomPermission => 'Su invito';

  @override
  String get createRoomPermissionDescription =>
      'I nuovi membri devono essere approvati da un admin';

  @override
  String get joinRoomTitle => 'Unisciti a Comunità';

  @override
  String get joinRoomHaveCode => 'Hai un codice?';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix =>
      'I codici delle comunità sono di 6 caratteri';

  @override
  String get joinRoomNotFound => 'Nessuna comunità trovata con quel codice';

  @override
  String joinRoomRequestSent(String name) {
    return 'Richiesta inviata. In attesa dell\'approvazione di un admin di \"$name\".';
  }

  @override
  String get joinRoomSearch => 'O cerca comunità pubbliche';

  @override
  String get joinRoomSearchHint => 'Nome della comunità…';

  @override
  String get joinRoomNoResults => 'Nessuna comunità pubblica corrispondente.';

  @override
  String get joinRoomPermissionOnly =>
      'Le comunità su invito si possono raggiungere solo con il loro codice.';

  @override
  String joinRoomMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get joinRoomJoin => 'Unisciti';

  @override
  String get roomDetailSettings => 'Impostazioni comunità';

  @override
  String get roomDetailMembers => 'Membri';

  @override
  String get roomDetailCouldNotLoadPosts => 'Impossibile caricare i post.';

  @override
  String get roomDetailEmptyTitle => 'Nessun huddle in questa comunità';

  @override
  String get roomDetailEmptyBody =>
      'Scatta una foto dalla fotocamera per essere il primo.';

  @override
  String get roomSettingsTitle => 'Impostazioni Comunità';

  @override
  String get roomSettingsRename => 'Rinomina comunità';

  @override
  String get roomSettingsModeration => 'Moderazione';

  @override
  String get roomSettingsPendingJoinRequests => 'Richieste in sospeso';

  @override
  String roomSettingsMembersCount(int count) {
    return 'Membri ($count)';
  }

  @override
  String get roomSettingsLeaveRoom => 'Lascia la comunità';

  @override
  String get roomSettingsDeleteRoom => 'Elimina comunità';

  @override
  String get roomSettingsPublic => 'Pubblica';

  @override
  String get roomSettingsPermission => 'Su invito';

  @override
  String get roomSettingsRoomCode => 'Codice della comunità';

  @override
  String get roomSettingsCodeCopied => 'Codice copiato!';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return 'Unisciti alla mia comunità \"$name\" su Huddlex — usa il codice $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return 'Unisciti a $name su Huddlex';
  }

  @override
  String get roomSettingsRequirePostApproval =>
      'Richiedi approvazione dei post';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      'I post dei membri normali attendono l\'approvazione dell\'admin. Admin e utenti fidati pubblicano subito.';

  @override
  String get roomSettingsReviewPending => 'Rivedi i post in sospeso';

  @override
  String get roomSettingsNoPending => 'Nessuna richiesta in sospeso';

  @override
  String get roomSettingsTrustedTag => 'Fidato — salta l\'approvazione';

  @override
  String get roomSettingsMakeAdmin => 'Rendi admin';

  @override
  String get roomSettingsRemoveAdmin => 'Rimuovi admin';

  @override
  String get roomSettingsRemoveTrusted => 'Rimuovi stato fidato';

  @override
  String get roomSettingsMarkTrusted => 'Segna come fidato';

  @override
  String get roomSettingsRemoveFromRoom => 'Rimuovi dalla comunità';

  @override
  String get roomSettingsRemoveMemberTitle => 'Rimuovere il membro?';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return '$member sarà rimosso da \"$room\".';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return 'Aggiornamento foto fallito: $error';
  }

  @override
  String get roomSettingsNewName => 'Nuovo nome';

  @override
  String get roomSettingsLeaveTitle => 'Lasciare la comunità?';

  @override
  String roomSettingsLeaveBody(String name) {
    return 'Smetterai di ricevere momenti da \"$name\".';
  }

  @override
  String get roomSettingsLeave => 'Lascia';

  @override
  String get roomSettingsDeleteTitle => 'Eliminare la comunità?';

  @override
  String roomSettingsDeleteBody(String name) {
    return '\"$name\" sarà eliminata definitivamente per tutti i membri. Operazione irreversibile.';
  }

  @override
  String pendingPostsTitle(String room) {
    return 'In sospeso — $room';
  }

  @override
  String get pendingPostsEmpty => 'Nulla in attesa di approvazione.';

  @override
  String get pendingPostsReject => 'Rifiuta';

  @override
  String get pendingPostsApprove => 'Approva';

  @override
  String get cameraTitle => 'Nuovo Huddle';

  @override
  String get cameraNoRooms =>
      'Unisciti o crea una comunità prima di pubblicare momenti.';

  @override
  String get cameraProcessingVideo => 'Elaborazione video…';

  @override
  String get cameraMuted => 'Silenziato';

  @override
  String get cameraCaptureHint => 'Scatta una foto o un clip di 6 secondi';

  @override
  String get cameraPhoto => 'Foto';

  @override
  String get cameraVideo => 'Video';

  @override
  String get cameraPhotoFromGallery => 'Foto dalla galleria';

  @override
  String get cameraVideoFromGallery => 'Video dalla galleria';

  @override
  String get cameraRetake => 'Ripeti';

  @override
  String get cameraPostClip => 'Pubblica clip';

  @override
  String get cameraPostMomento => 'Pubblica Huddle';

  @override
  String get cameraCaptionHint => 'Aggiungi una didascalia (opzionale)';

  @override
  String get cameraPostTo => 'Pubblica in';

  @override
  String cameraActiveRoomsCount(int count) {
    return 'Comunità attive ($count)';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return 'Tutte le comunità ($count)';
  }

  @override
  String get cameraPickRooms => 'Scegli…';

  @override
  String get cameraPickAtLeastOne => 'Scegli almeno una comunità';

  @override
  String cameraPostedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pubblicato in $count comunità!',
      one: 'Pubblicato in 1 comunità!',
    );
    return '$_temp0';
  }

  @override
  String cameraPendingApproval(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count post in attesa di approvazione.',
      one: '1 post in attesa di approvazione.',
    );
    return '$_temp0';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live pubblicati, $pending in attesa di approvazione.';
  }

  @override
  String cameraFailedToSend(String error) {
    return 'Invio fallito: $error';
  }

  @override
  String get cameraCouldNotProcessVideo => 'Impossibile elaborare il video.';

  @override
  String get cameraVideoTooLong => 'Il video deve durare 6 secondi o meno.';

  @override
  String get cameraCouldNotPoster =>
      'Impossibile generare l\'immagine di copertina.';

  @override
  String get accountTitle => 'Il mio Account';

  @override
  String get accountActiveRooms => 'Comunità Attive';

  @override
  String get accountActiveRoomsDescription =>
      'I post vanno qui di default. Attiva/disattiva nella scheda Comunità.';

  @override
  String get accountFavoriteRooms => 'Comunità Preferite';

  @override
  String get accountFavoriteRoomsDescription =>
      'I preferiti salgono in cima al feed e alla rotazione del widget.';

  @override
  String get accountBlockedUsers => 'Utenti Bloccati';

  @override
  String get accountLegal => 'Note legali';

  @override
  String get accountTermsOfService => 'Termini del Servizio';

  @override
  String get accountPrivacyPolicy => 'Informativa sulla Privacy';

  @override
  String get accountSignOut => 'Esci';

  @override
  String get accountDeleteMy => 'Elimina il mio account';

  @override
  String get accountDeleteTitle => 'Eliminare il tuo account?';

  @override
  String get accountDeleteBody =>
      'Questo rimuoverà definitivamente il tuo account, le iscrizioni a tutte le comunità e i preferiti. I post scadranno naturalmente. Operazione irreversibile.';

  @override
  String get accountReauthRequired =>
      'Esci e rientra, poi riprova a eliminare.';

  @override
  String accountFailedWithMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String accountRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comunità',
      one: '1 comunità',
    );
    return '$_temp0';
  }

  @override
  String get accountEditProfile => 'Modifica profilo';

  @override
  String accountStreakDays(int count) {
    return 'Striscia di $count giorni';
  }

  @override
  String accountStreakBest(int count) {
    return 'Record: $count giorni';
  }

  @override
  String get accountStreakKeepGoing => 'Continua — pubblica oggi';

  @override
  String get accountNoBlocked => 'Nessun utente bloccato';

  @override
  String get accountUnblock => 'Sblocca';

  @override
  String get accountLanguage => 'Lingua';

  @override
  String get accountLanguageSystem => 'Lingua del sistema';

  @override
  String get accountNoActiveRooms => 'Nessuna comunità attiva';

  @override
  String get accountNoFavorites => 'Nessun preferito';

  @override
  String get roomSettingsCreator => 'Creatore';

  @override
  String get roomSettingsAdmin => 'Admin';

  @override
  String get editProfileTitle => 'Modifica Profilo';

  @override
  String get editProfileTapPhoto => 'Tocca per cambiare la foto';

  @override
  String get editProfileDisplayName => 'Nome visualizzato';

  @override
  String get editProfileNameRequired => 'Il nome non può essere vuoto';

  @override
  String editProfileFailedSave(String error) {
    return 'Salvataggio fallito: $error';
  }

  @override
  String get postActionsReportTitle => 'Segnala questo post';

  @override
  String get postActionsReportPrompt => 'Perché stai segnalando questo post?';

  @override
  String get postActionsReportPlaceholder => 'Opzionale — descrivi cosa non va';

  @override
  String get postActionsReportSubmitted => 'Segnalazione inviata. Grazie.';

  @override
  String postActionsBlockUser(String name) {
    return 'Blocca $name';
  }

  @override
  String get postActionsBlockDescription =>
      'Non vedrai i suoi post in nessuna comunità';

  @override
  String postActionsUserBlocked(String name) {
    return '$name bloccato.';
  }

  @override
  String get postActionsOwnPost => 'Questo è il tuo post';

  @override
  String get postActionsNoActions =>
      'Nessuna azione di moderazione disponibile';

  @override
  String postActionsBlockTitle(String name) {
    return 'Bloccare $name?';
  }

  @override
  String postActionsBlockBody(String name) {
    return 'Non vedrai i post di $name in nessuna comunità. Non verrà notificato.';
  }

  @override
  String get postActionsBlock => 'Blocca';

  @override
  String likedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Piace a $count persone',
      one: 'Piace a 1 persona',
    );
    return '$_temp0';
  }
}
