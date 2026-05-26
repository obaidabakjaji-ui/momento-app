// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Momento';

  @override
  String get appTagline => 'Cada momento, compartido con belleza';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonShare => 'Compartir';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSubmit => 'Enviar';

  @override
  String get commonSomethingWentWrong => 'Algo salió mal';

  @override
  String commonFailedWithError(String error) {
    return 'Error: $error';
  }

  @override
  String get commonYouAreOffline => 'Estás sin conexión';

  @override
  String get authYourName => 'Tu nombre';

  @override
  String get authYourNameHint => 'Introduce tu nombre';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authEmailHint => 'Introduce un correo válido';

  @override
  String get authEmailPlaceholder => 'tu@ejemplo.com';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authPasswordHint => 'Mínimo 6 caracteres';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authSignOut => 'Cerrar sesión';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authAlreadyHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get authByCreatingYouAgree => 'Al crear una cuenta aceptas nuestros ';

  @override
  String get authBySigningInYouAgree => 'Al iniciar sesión aceptas nuestros ';

  @override
  String get authTerms => 'Términos';

  @override
  String get authPrivacyPolicy => 'Política de Privacidad';

  @override
  String get authResetPasswordTitle => 'Restablecer contraseña';

  @override
  String get authResetPasswordDescription =>
      'Introduce tu correo y te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get authSend => 'Enviar';

  @override
  String authResetLinkSent(String email) {
    return 'Enlace de restablecimiento enviado a $email';
  }

  @override
  String get verifyTitle => 'Revisa tu correo';

  @override
  String verifyDescription(String email) {
    return 'Enviamos un código de 6 dígitos a $email. Ingrésalo abajo para confirmar tu cuenta.';
  }

  @override
  String get verifyCodeSent => 'Código enviado — revisa tu bandeja de entrada.';

  @override
  String get verifyCodeSentNew =>
      'Nuevo código enviado — revisa tu bandeja de entrada.';

  @override
  String get verifyCodeFailed =>
      'No se pudo enviar el código. Toca reenviar para reintentar.';

  @override
  String get verifyCodeFailedNew =>
      'No se pudo enviar un nuevo código. Reintenta.';

  @override
  String get verifySomethingWrong => 'Algo salió mal. Reintenta.';

  @override
  String verifyResendIn(int seconds) {
    return 'Reenviar código en $seconds s';
  }

  @override
  String get verifyResend => 'Reenviar código';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a Momento';

  @override
  String get onboardingWelcomeBody =>
      'Comparte momentos sin filtros con quienes más te importan. Sin contadores de \"me gusta\", sin algoritmos — solo pequeños vistazos de tu día.';

  @override
  String get onboardingRoomsTitle => 'Crea o únete a Comunidades';

  @override
  String get onboardingRoomsBody =>
      'Una Comunidad es un espacio privado para compartir fotos. Crea una para tu familia, tu viaje, tu grupo de amigos — e invita con un código de 6 caracteres.';

  @override
  String get onboardingExpireTitle => 'Las fotos desaparecen en 6 horas';

  @override
  String get onboardingExpireBody =>
      'Cada foto expira automáticamente. Captura, comparte y sigue adelante — sin archivo, sin presión.';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get homeFeed => 'Feed';

  @override
  String get homeRooms => 'Comunidades';

  @override
  String get homeAccount => 'Cuenta';

  @override
  String get homeNewMomento => 'Nuevo Momento';

  @override
  String get homeCouldNotLoadAccount => 'No se pudo cargar tu cuenta.';

  @override
  String get homeCouldNotLoadRooms => 'No se pudieron cargar tus comunidades.';

  @override
  String get homeCouldNotLoadPosts =>
      'No se pudieron cargar las publicaciones.';

  @override
  String get homeNoRoomsTitle => 'Aún no hay comunidades';

  @override
  String get homeNoRoomsHomeBody =>
      'Abre la pestaña Comunidades para crear o unirte a una.';

  @override
  String get homeNoMomentosTitle => 'Aún no hay momentos';

  @override
  String get homeNoMomentosBody =>
      '¡Toma una foto y compártela con tus comunidades!';

  @override
  String get homeExpired => 'Expirado';

  @override
  String homeTimeRemaining(int hours, int minutes) {
    return '$hours h $minutes m restantes';
  }

  @override
  String get roomsMyRooms => 'Mis Comunidades';

  @override
  String get roomsJoinByCode => 'Unirse con código';

  @override
  String get roomsCreateRoom => 'Crear Comunidad';

  @override
  String get roomsJoinRoom => 'Unirse a Comunidad';

  @override
  String get roomsEmptyTitle => 'Aún no hay comunidades';

  @override
  String get roomsEmptyBody =>
      'Crea una nueva comunidad o únete a una con un código para empezar a compartir momentos.';

  @override
  String get roomsCodePrefix => 'Código ';

  @override
  String get roomsFavorite => 'Favorito';

  @override
  String get roomsUnfavorite => 'Quitar favorito';

  @override
  String get roomsActivate => 'Activar';

  @override
  String get roomsDeactivate => 'Desactivar';

  @override
  String get createRoomTitle => 'Crear Comunidad';

  @override
  String get createRoomPhotoLabel => 'Foto de la comunidad (opcional)';

  @override
  String get createRoomNameLabel => 'Nombre de la comunidad';

  @override
  String get createRoomNameHint => 'ej. Familia, Viaje 2026, Mejores amigos';

  @override
  String get createRoomNameRequired => 'Por favor introduce un nombre';

  @override
  String get createRoomWhoCanJoin => '¿Quién puede unirse?';

  @override
  String get createRoomPublic => 'Pública';

  @override
  String get createRoomPublicDescription =>
      'Cualquiera con el código puede unirse al instante';

  @override
  String get createRoomPermission => 'Con permiso';

  @override
  String get createRoomPermissionDescription =>
      'Los nuevos miembros deben ser aprobados por un administrador';

  @override
  String get joinRoomTitle => 'Unirse a Comunidad';

  @override
  String get joinRoomHaveCode => '¿Tienes un código?';

  @override
  String get joinRoomCodePlaceholder => 'A7BX92';

  @override
  String get joinRoomCodeMustBeSix =>
      'Los códigos de comunidad tienen 6 caracteres';

  @override
  String get joinRoomNotFound =>
      'No se encontró ninguna comunidad con ese código';

  @override
  String joinRoomRequestSent(String name) {
    return 'Solicitud enviada. Esperando aprobación de un admin de \"$name\".';
  }

  @override
  String get joinRoomSearch => 'O busca comunidades públicas';

  @override
  String get joinRoomSearchHint => 'Nombre de la comunidad…';

  @override
  String get joinRoomNoResults => 'No hay comunidades públicas que coincidan.';

  @override
  String get joinRoomPermissionOnly =>
      'A las comunidades con permiso solo se puede entrar con su código.';

  @override
  String joinRoomMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get joinRoomJoin => 'Unirse';

  @override
  String get roomDetailSettings => 'Ajustes de la comunidad';

  @override
  String get roomDetailMembers => 'Miembros';

  @override
  String get roomDetailCouldNotLoadPosts =>
      'No se pudieron cargar las publicaciones.';

  @override
  String get roomDetailEmptyTitle => 'Aún no hay momentos en esta comunidad';

  @override
  String get roomDetailEmptyBody =>
      'Toma una foto desde la cámara para ser el primero.';

  @override
  String get roomSettingsTitle => 'Ajustes de la Comunidad';

  @override
  String get roomSettingsRename => 'Renombrar comunidad';

  @override
  String get roomSettingsModeration => 'Moderación';

  @override
  String get roomSettingsPendingJoinRequests => 'Solicitudes pendientes';

  @override
  String roomSettingsMembersCount(int count) {
    return 'Miembros ($count)';
  }

  @override
  String get roomSettingsLeaveRoom => 'Salir de la comunidad';

  @override
  String get roomSettingsDeleteRoom => 'Eliminar comunidad';

  @override
  String get roomSettingsPublic => 'Pública';

  @override
  String get roomSettingsPermission => 'Con permiso';

  @override
  String get roomSettingsRoomCode => 'Código de la comunidad';

  @override
  String get roomSettingsCodeCopied => '¡Código copiado!';

  @override
  String roomSettingsShareMessage(String name, String code) {
    return 'Únete a mi comunidad \"$name\" en Momento — usa el código $code';
  }

  @override
  String roomSettingsShareSubject(String name) {
    return 'Únete a $name en Momento';
  }

  @override
  String get roomSettingsRequirePostApproval =>
      'Requerir aprobación de publicaciones';

  @override
  String get roomSettingsRequirePostApprovalDescription =>
      'Las publicaciones de los miembros regulares esperan la aprobación del admin. Los admins y usuarios de confianza publican al instante.';

  @override
  String get roomSettingsReviewPending => 'Revisar publicaciones pendientes';

  @override
  String get roomSettingsNoPending => 'No hay solicitudes pendientes';

  @override
  String get roomSettingsTrustedTag => 'De confianza — omite la aprobación';

  @override
  String get roomSettingsMakeAdmin => 'Hacer admin';

  @override
  String get roomSettingsRemoveAdmin => 'Quitar admin';

  @override
  String get roomSettingsRemoveTrusted => 'Quitar confianza';

  @override
  String get roomSettingsMarkTrusted => 'Marcar como de confianza';

  @override
  String get roomSettingsRemoveFromRoom => 'Quitar de la comunidad';

  @override
  String get roomSettingsRemoveMemberTitle => '¿Quitar miembro?';

  @override
  String roomSettingsRemoveMemberBody(String member, String room) {
    return '$member será quitado de \"$room\".';
  }

  @override
  String roomSettingsFailedUpdatePhoto(String error) {
    return 'Error al actualizar la foto: $error';
  }

  @override
  String get roomSettingsNewName => 'Nuevo nombre';

  @override
  String get roomSettingsLeaveTitle => '¿Salir de la comunidad?';

  @override
  String roomSettingsLeaveBody(String name) {
    return 'Dejarás de recibir momentos de \"$name\".';
  }

  @override
  String get roomSettingsLeave => 'Salir';

  @override
  String get roomSettingsDeleteTitle => '¿Eliminar comunidad?';

  @override
  String roomSettingsDeleteBody(String name) {
    return '\"$name\" se eliminará permanentemente para todos los miembros. Esta acción no se puede deshacer.';
  }

  @override
  String pendingPostsTitle(String room) {
    return 'Pendientes — $room';
  }

  @override
  String get pendingPostsEmpty => 'Nada esperando aprobación.';

  @override
  String get pendingPostsReject => 'Rechazar';

  @override
  String get pendingPostsApprove => 'Aprobar';

  @override
  String get cameraTitle => 'Nuevo Momento';

  @override
  String get cameraNoRooms =>
      'Únete o crea una comunidad primero para publicar momentos.';

  @override
  String get cameraProcessingVideo => 'Procesando video…';

  @override
  String get cameraMuted => 'Silenciado';

  @override
  String get cameraCaptureHint => 'Captura una foto o un clip de 6 segundos';

  @override
  String get cameraPhoto => 'Foto';

  @override
  String get cameraVideo => 'Video';

  @override
  String get cameraPhotoFromGallery => 'Foto desde galería';

  @override
  String get cameraVideoFromGallery => 'Video desde galería';

  @override
  String get cameraRetake => 'Repetir';

  @override
  String get cameraPostClip => 'Publicar clip';

  @override
  String get cameraPostMomento => 'Publicar Momento';

  @override
  String get cameraCaptionHint => 'Añade un pie de foto (opcional)';

  @override
  String get cameraPostTo => 'Publicar en';

  @override
  String cameraActiveRoomsCount(int count) {
    return 'Comunidades activas ($count)';
  }

  @override
  String cameraAllRoomsCount(int count) {
    return 'Todas las comunidades ($count)';
  }

  @override
  String get cameraPickRooms => 'Elegir…';

  @override
  String get cameraPickAtLeastOne => 'Elige al menos una comunidad';

  @override
  String cameraPostedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡Publicado en $count comunidades!',
      one: '¡Publicado en 1 comunidad!',
    );
    return '$_temp0';
  }

  @override
  String cameraPendingApproval(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publicaciones pendientes de aprobación.',
      one: '1 publicación pendiente de aprobación.',
    );
    return '$_temp0';
  }

  @override
  String cameraLiveAndPending(int live, int pending) {
    return '$live publicada(s), $pending pendientes de aprobación.';
  }

  @override
  String cameraFailedToSend(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get cameraCouldNotProcessVideo => 'No se pudo procesar el video.';

  @override
  String get cameraVideoTooLong => 'El video debe durar 6 segundos o menos.';

  @override
  String get cameraCouldNotPoster => 'No se pudo generar la imagen de portada.';

  @override
  String get accountTitle => 'Mi Cuenta';

  @override
  String get accountActiveRooms => 'Comunidades Activas';

  @override
  String get accountActiveRoomsDescription =>
      'Las publicaciones van aquí por defecto. Activa/desactiva en la pestaña Comunidades.';

  @override
  String get accountFavoriteRooms => 'Comunidades Favoritas';

  @override
  String get accountFavoriteRoomsDescription =>
      'Las favoritas suben al inicio del feed y de la rotación del widget.';

  @override
  String get accountBlockedUsers => 'Usuarios Bloqueados';

  @override
  String get accountLegal => 'Legal';

  @override
  String get accountTermsOfService => 'Términos del Servicio';

  @override
  String get accountPrivacyPolicy => 'Política de Privacidad';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountDeleteMy => 'Eliminar mi cuenta';

  @override
  String get accountDeleteTitle => '¿Eliminar tu cuenta?';

  @override
  String get accountDeleteBody =>
      'Esto eliminará permanentemente tu cuenta, membresías en todas las comunidades y favoritos. Las publicaciones expirarán naturalmente. No se puede deshacer.';

  @override
  String get accountReauthRequired =>
      'Por favor cierra sesión y vuelve a iniciar, luego intenta eliminar de nuevo.';

  @override
  String accountFailedWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String accountRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comunidades',
      one: '1 comunidad',
    );
    return '$_temp0';
  }

  @override
  String get accountEditProfile => 'Editar perfil';

  @override
  String accountStreakDays(int count) {
    return 'Racha de $count días';
  }

  @override
  String accountStreakBest(int count) {
    return 'Mejor: $count días';
  }

  @override
  String get accountStreakKeepGoing => '¡Sigue así — publica hoy!';

  @override
  String get accountNoBlocked => 'No hay usuarios bloqueados';

  @override
  String get accountUnblock => 'Desbloquear';

  @override
  String get accountLanguage => 'Idioma';

  @override
  String get accountLanguageSystem => 'Predeterminado del sistema';

  @override
  String get accountNoActiveRooms => 'Sin comunidades activas';

  @override
  String get accountNoFavorites => 'Sin favoritos';

  @override
  String get roomSettingsCreator => 'Creador';

  @override
  String get roomSettingsAdmin => 'Admin';

  @override
  String get editProfileTitle => 'Editar Perfil';

  @override
  String get editProfileTapPhoto => 'Toca para cambiar la foto';

  @override
  String get editProfileDisplayName => 'Nombre mostrado';

  @override
  String get editProfileNameRequired => 'El nombre no puede estar vacío';

  @override
  String editProfileFailedSave(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get postActionsReportTitle => 'Reportar esta publicación';

  @override
  String get postActionsReportPrompt => '¿Por qué reportas esta publicación?';

  @override
  String get postActionsReportPlaceholder => 'Opcional — describe qué está mal';

  @override
  String get postActionsReportSubmitted => 'Reporte enviado. Gracias.';

  @override
  String postActionsBlockUser(String name) {
    return 'Bloquear a $name';
  }

  @override
  String get postActionsBlockDescription =>
      'No verás sus publicaciones en ninguna comunidad';

  @override
  String postActionsUserBlocked(String name) {
    return '$name bloqueado.';
  }

  @override
  String get postActionsOwnPost => 'Esta es tu propia publicación';

  @override
  String get postActionsNoActions =>
      'No hay acciones de moderación disponibles';

  @override
  String postActionsBlockTitle(String name) {
    return '¿Bloquear a $name?';
  }

  @override
  String postActionsBlockBody(String name) {
    return 'No verás las publicaciones de $name en ninguna comunidad. No será notificado.';
  }

  @override
  String get postActionsBlock => 'Bloquear';

  @override
  String likedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Le gustó a $count personas',
      one: 'Le gustó a 1 persona',
    );
    return '$_temp0';
  }
}
