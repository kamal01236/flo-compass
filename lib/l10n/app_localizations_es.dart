// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tabDiscover => 'Descubrir';

  @override
  String get tabCompanion => 'Pregunta a Flo';

  @override
  String get tabMeets => 'Meets';

  @override
  String get tabMyPlan => 'Mi plan';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get loading => 'Cargando…';

  @override
  String get retry => 'Reintentar';

  @override
  String get emptyTitle => 'Aún no hay nada aquí';

  @override
  String get consentTitle => 'Privacidad y uso de datos';

  @override
  String get consentBody =>
      'Flo Compass guarda tu plan, intereses y ajustes localmente en tu navegador. Usamos estos datos para personalizar recomendaciones de sesiones. Accelevents gestiona el registro oficial — esta app no lo reemplaza.';

  @override
  String get consentAccept => 'Aceptar y continuar';

  @override
  String get consentDecline => 'Rechazar';

  @override
  String get consentReadPolicy => 'Leer política de privacidad completa';

  @override
  String get consentRequiredTitle => 'Consentimiento requerido';

  @override
  String get consentRequiredBody =>
      'Debes aceptar la política de privacidad para usar Flo Compass. Ningún dato personal sale de tu dispositivo sin tu consentimiento.';

  @override
  String get consentOk => 'OK';

  @override
  String get profileLogin => 'Iniciar sesión';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String profileSignedInAs(String name) {
    return 'Sesión iniciada como $name';
  }

  @override
  String get profileScreenTitle => 'Perfil';

  @override
  String get profileTabYou => 'Tú';

  @override
  String get profileTabProgress => 'Progreso';

  @override
  String get profileTabSettings => 'Ajustes';

  @override
  String get profileTabOrganizer => 'Organizador';

  @override
  String get profileTabAdmin => 'Admin';

  @override
  String get profileMoreOptions => 'Más opciones';

  @override
  String get profileInstallApp => 'Instalar app';

  @override
  String get profileInstallFallback =>
      'Usa el menú del navegador para instalar esta app';

  @override
  String get localeLabel => 'Idioma';

  @override
  String get localeEn => 'English';

  @override
  String get localeDe => 'Deutsch';

  @override
  String get localeEs => 'Español';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get reportIssue => 'Reportar problema';

  @override
  String get commonDismiss => 'Descartar';

  @override
  String aboutVersion(String version, String build) {
    return 'Versión $version ($build)';
  }

  @override
  String get accessibilityStatement => 'Declaración de accesibilidad';

  @override
  String get offlineBanner =>
      'Estás sin conexión — mostrando datos guardados de Flo 2026.';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Sin alertas próximas';

  @override
  String get notificationsEmptySubtitle =>
      'Tus sesiones guardadas aparecerán aquí.';

  @override
  String get notificationsTooltip => 'Notificaciones';

  @override
  String notificationsBellLabelWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notificaciones, $count alertas',
      one: 'Notificaciones, 1 alerta',
      zero: 'Sin notificaciones',
    );
    return '$_temp0';
  }

  @override
  String get notificationsRefreshAgenda => 'Actualizar agenda';

  @override
  String get notificationsDismiss => 'Descartar';

  @override
  String get authCompletingSignIn => 'Completando inicio de sesión…';

  @override
  String get authSignInFailed => 'No se pudo completar el inicio de sesión.';

  @override
  String get tourNowNextTitle => 'Qué está en vivo';

  @override
  String get tourNowNextBody =>
      'Tu reloj del evento — qué está en vivo y qué viene después.';

  @override
  String get tourDiscoverTitle => 'Buscar sesiones';

  @override
  String get tourDiscoverBody =>
      'Encuentra charlas por título, ponente o tema. Los filtros y recomendaciones se actualizan al escribir.';

  @override
  String get tourRecoReasonTitle => 'Por qué lo elegimos';

  @override
  String get tourRecoReasonBody =>
      'Cada recomendación muestra su razonamiento — sin caja negra.';

  @override
  String get tourSessionTitle => 'Guardar en Mi plan';

  @override
  String get tourSessionBody =>
      'Marca las sesiones que quieres asistir. Tu lista queda en este dispositivo — separada del registro de Accelevents.';

  @override
  String get tourLogisticsTitle => 'Abrir logística';

  @override
  String get tourLogisticsBody =>
      'Detalles del lugar, tiempos de caminata y acciones del campus están aquí.';

  @override
  String get tourVenueMapTitle => 'Ver en el mapa';

  @override
  String get tourVenueMapBody => 'Toca Mapa para ver esta sala en el campus.';

  @override
  String get tourCompanionTitle => 'Pregunta a Flo';

  @override
  String get tourCompanionBody =>
      'Sesiones, baños, estacionamiento, conflictos — prueba \'Where can I park my car?\'';

  @override
  String get tourMyPlanTitle => 'Tu lista';

  @override
  String get tourMyPlanBody =>
      'Revisa sesiones guardadas, exporta tu plan y detecta conflictos de horario antes de ir a una sala.';

  @override
  String get tourNext => 'Siguiente';

  @override
  String get tourBack => 'Atrás';

  @override
  String get tourSkip => 'Saltar tour';

  @override
  String get tourDone => 'Listo';

  @override
  String get replayTour => 'Repetir tour';

  @override
  String tourStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a Flo Compass';

  @override
  String get onboardingEditTitle => 'Actualizar tus intereses';

  @override
  String get onboardingWelcomeBody =>
      'Flo 2026 en la oficina Nagarro Gurgaon — ~640 sesiones en 90 espacios (planta baja + pisos 6–13). Complementamos Accelevents ayudándote a elegir lo que importa.';

  @override
  String get onboardingEditBody =>
      'Ajusta tu rol e intereses — las clasificaciones de Descubrir se actualizarán al guardar.';

  @override
  String get onboardingRoleTitle => 'Tu rol';

  @override
  String get onboardingAttendanceTitle => '¿Cómo asistes?';

  @override
  String get onboardingAttendanceHint =>
      'Flo complementa Accelevents. El modo remoto oculta indicaciones a pie en el detalle de sesión y destaca sesiones aptas para streaming.';

  @override
  String get onboardingOnSite => 'Presencial en Gurgaon';

  @override
  String get onboardingRemote => 'Remoto / hub';

  @override
  String get onboardingInterestsTitle => 'Elige 3–7 intereses';

  @override
  String get onboardingInterestGroupAiData => 'IA y datos';

  @override
  String get onboardingInterestGroupEngineering => 'Ingeniería';

  @override
  String get onboardingInterestGroupStrategy => 'Estrategia';

  @override
  String get onboardingInterestGroupDomain => 'Dominio';

  @override
  String get onboardingInterestGroupCrossCutting => 'Transversal';

  @override
  String get onboardingSelectMin => 'Selecciona al menos 3 intereses';

  @override
  String onboardingContinue(int count) {
    return 'Continuar ($count/7)';
  }

  @override
  String onboardingSave(int count) {
    return 'Guardar cambios ($count/7)';
  }

  @override
  String onboardingRoleSemantic(String label) {
    return 'Rol $label';
  }

  @override
  String onboardingInterestSemantic(String label) {
    return 'Interés $label';
  }

  @override
  String get onboardingAttendanceSemantic => 'Modo de asistencia';

  @override
  String get profileAppearanceSection => 'Apariencia e idioma';

  @override
  String get profileTheme => 'Tema';

  @override
  String get profileThemeSubtitle => 'Seguir el sistema o anular.';

  @override
  String get profileThemeSystem => 'Sistema';

  @override
  String get profileThemeLight => 'Claro';

  @override
  String get profileThemeDark => 'Oscuro';

  @override
  String get profileThemeHighContrast => 'Alto contraste';

  @override
  String get profileDyslexiaFont => 'Fuente para dislexia';

  @override
  String get profileDyslexiaFontSubtitle =>
      'OpenDyslexic (OFL) · añade ~120 KB de descarga';

  @override
  String get profilePlainEnglish => 'Resúmenes en lenguaje claro';

  @override
  String get profilePlainEnglishSubtitle =>
      'Resúmenes breves basados en reglas en las tarjetas de Descubrir';

  @override
  String get profileEventExperienceSection => 'Experiencia del evento';

  @override
  String get profileAttendanceMode => 'Modo de asistencia';

  @override
  String get profileAttendanceModeSubtitle => 'Presencial o remoto.';

  @override
  String get profileAttendanceOnSite => 'Presencial';

  @override
  String get profileAttendanceRemote => 'Remoto';

  @override
  String get profileEventDayMode => 'Modo día del evento';

  @override
  String get profileEventDayModeSubtitle =>
      'Auto, activado o desactivado para la barra Ahora/Siguiente.';

  @override
  String get profileEventDayAuto => 'Auto';

  @override
  String get profileEventDayOn => 'Activado';

  @override
  String get profileEventDayOff => 'Desactivado';

  @override
  String get profileLowBandwidth => 'Modo bajo ancho de banda';

  @override
  String get profileLowBandwidthSubtitle =>
      'Imágenes más pequeñas, sin animación de escritura, solo lista en Descubrir.';

  @override
  String get profileNotificationsSection => 'Notificaciones';

  @override
  String get profileAgendaChangeAlerts => 'Alertas de cambios en la agenda';

  @override
  String get profileAgendaChangeAlertsSubtitle =>
      'Alertas en la app para sesiones en Mi plan o de ponentes que sigues.';

  @override
  String get profileAgendaChangeAlertsDisabledSnack =>
      'Las alertas de cambios en la agenda están desactivadas. Reactívalas aquí para actualizaciones de sala, hora o cancelación.';

  @override
  String get profileAgendaChangePush => 'Push de cambios en la agenda';

  @override
  String get profileAgendaChangePushSubtitle =>
      'Próximamente — push del navegador para actualizaciones de agenda.';

  @override
  String get profileLeaveNowReminders => 'Recordatorios de salir ahora';

  @override
  String get profileLeaveNowReminderUnsupported =>
      'No compatible con este navegador (p. ej. Safari en iPhone). Los recordatorios en la app siguen funcionando.';

  @override
  String get profileLeaveNowReminderDenied =>
      'Activa en los ajustes del navegador para recibir alertas de caminata con 5 min de margen.';

  @override
  String get profileLeaveNowReminderEnabled =>
      'Tiempo de caminata más 5 min de margen antes de sesiones planificadas.';

  @override
  String get profileNotificationPermissionDeniedSnack =>
      'No se concedió permiso de notificaciones.';

  @override
  String get profileEnableBusinessCard => 'Activar tarjeta de visita';

  @override
  String get profileDemoAccessTitle => 'Acceso demo';

  @override
  String get profileDemoAccessBody =>
      'Elige un usuario simulado para previsualizar herramientas de organizador o admin.';

  @override
  String profileDemoPlatformAccess(String label, String organizationLabel) {
    return 'Acceso a la plataforma: $label$organizationLabel';
  }

  @override
  String get profileOpenOrganizerTab => 'Abrir pestaña Organizador';

  @override
  String get profileOpenAdminTab => 'Abrir pestaña Admin';

  @override
  String get profileSwitchUser => 'Cambiar usuario';

  @override
  String get sessionLeaveNow => 'Salir ahora';

  @override
  String get sessionAddToMyPlan => 'Añadir a Mi plan';

  @override
  String get sessionAddToPlan => 'Añadir al plan';

  @override
  String get sessionJoinStream => 'Unirse al stream';

  @override
  String get sessionMarkAsAttended => 'Marcar como asistida';

  @override
  String get sessionMarkAttended => 'Marcar asistida';

  @override
  String get sessionInPlan => 'En el plan';

  @override
  String get sessionAdded => 'Añadida';

  @override
  String get sessionAddToCalendar => 'Añadir al calendario';

  @override
  String get sessionAddToCalendarTooltip => 'Añadir al calendario';

  @override
  String get myPlanEmptyTitle => 'Tu lista está vacía';

  @override
  String get myPlanEmptyMessage =>
      'Marca sesiones desde Descubrir. Este es un plan local — no la agenda oficial de Accelevents.';

  @override
  String get myPlanBrowseSessions => 'Explorar sesiones';

  @override
  String get myPlanAskFloDay1 => 'Pedir a Flo que arme mi Día 1';

  @override
  String get discoverEmptyFiltered => 'Ninguna sesión coincide con tus filtros';

  @override
  String get discoverEmptyFilteredHint =>
      'Prueba a limpiar filtros o ampliar intereses.';

  @override
  String get discoverHappeningNow => 'En curso ahora';

  @override
  String get discoverStartingSoon => 'Empieza pronto';

  @override
  String get floMeetsTitle => 'Flo Meets';

  @override
  String get floMeetsDetailTitle => 'Your Flo Meet';

  @override
  String get floMeetsEmptyTitle => 'No matches yet';

  @override
  String get floMeetsEmptyBody =>
      'When you\'re matched for a slot you selected, your meet will appear here.';

  @override
  String get floMeetsNotOptedInTitle => 'Set up Flo Meets';

  @override
  String get floMeetsNotOptedInBody =>
      'Add your matching preferences to join rooms and Connect with peers.';

  @override
  String get floMeetsEditPreferences => 'Preferences';

  @override
  String get floMeetsSavePreferences => 'Save';

  @override
  String get floMeetsSavingPreferences => 'Saving…';

  @override
  String get floMeetsSetupTitle => 'Set up Flo Meets';

  @override
  String get floMeetsSetupBody =>
      'Pick when you\'re free and how you\'d like to meet. You can change this anytime.';

  @override
  String get floMeetsSetupCta => 'Set up preferences';

  @override
  String get floMeetsSignInTitle => 'Sign in to use Flo Meets';

  @override
  String get floMeetsSignInBody =>
      'Flo Meets matching is available to signed-in attendees. Set your preferences here after you sign in.';

  @override
  String get floMeetsSignInUnavailable =>
      'Sign-in is not configured for this build.';

  @override
  String get floMeetsContinueWith => 'Continue with Flo Meets';

  @override
  String get floMeetsSkipOptIn => 'Skip Flo Meets for now';

  @override
  String get floMeetsViewMeets => 'View meets';

  @override
  String get floMeetsNotFound => 'Meet not found';

  @override
  String get floMeetsBackToList => 'Back to meets';

  @override
  String get floMeetsPartnerNickname => 'Nickname';

  @override
  String get floMeetsMeetLocation => 'Where to meet';

  @override
  String get floMeetsContactField => 'Contact';

  @override
  String get floMeetsMeetNote => 'Note';

  @override
  String floMeetsContactLine(String value) {
    return 'Contact: $value';
  }

  @override
  String get floMeetsOnboardingTitle => 'Flo Meets';

  @override
  String get floMeetsOnboardingBody =>
      'Meet people at Flo based on shared interests. Pick when you\'re free and where you\'d like to meet.';

  @override
  String get floMeetsOptInLabel => 'Join Flo Meets';

  @override
  String get floMeetsOptInHint =>
      'Opt in to get matched with other authenticated attendees.';

  @override
  String get floMeetsOnboardingFooter =>
      'You can update these anytime from Profile or Meets → Preferences.';

  @override
  String get meetNicknameLabel => 'Meet nickname';

  @override
  String get meetNicknameHint => '3–20 characters';

  @override
  String get meetNicknameSuggest => 'Suggest nickname';

  @override
  String get floMeetsIdentityTitle => 'I identify as';

  @override
  String get floMeetsOpenToTitle => 'Open to meet';

  @override
  String get floMeetsExperienceTitle => 'Years of experience';

  @override
  String get floMeetsExperienceRequired =>
      'Required for matching (±3 year band).';

  @override
  String get floMeetsExperienceYears => 'years';

  @override
  String get floMeetsPurposeTitle => 'Connection purpose';

  @override
  String get floMeetsPersonalInterestsTitle => 'Personal interests';

  @override
  String get floMeetsPersonalityTitle => 'Personality';

  @override
  String get floMeetsSlotsTitle => 'Availability (pick at least one)';

  @override
  String get floMeetsSlotsHint =>
      'Only the time slots you select here will be used for your Flo Meets.';

  @override
  String get floMeetsAmenityTitle => 'Where to meet';

  @override
  String get floMeetsAmenityHint => 'Pick a campus amenity';

  @override
  String get floMeetsContactMediumTitle => 'Share contact (optional)';

  @override
  String get floMeetsContactNone => 'None';

  @override
  String get floMeetsContactEmail => 'Email from Networking Card';

  @override
  String get floMeetsContactPhone => 'Phone from Networking Card';

  @override
  String get floMeetsContactLinkedin => 'LinkedIn from Networking Card';

  @override
  String get floMeetsContactEmptyWarning =>
      'Add this field in your Networking Card or clear your selection.';

  @override
  String get floMeetsMeetNoteTitle => 'Meet note (optional)';

  @override
  String get floMeetsMeetNoteHint =>
      'e.g. I\'ll be near registration in a blue jacket';

  @override
  String floMeetsProfileOptedIn(int count) {
    return '$count slots selected';
  }

  @override
  String floMeetsProfileSlotsReady(int count) {
    return '$count slots selected';
  }

  @override
  String get floMeetsProfileOptedOut => 'Preferences not set yet';

  @override
  String get floMeetsProfileSetupNeeded =>
      'Set up preferences to join match rooms and Connect.';

  @override
  String get floMeetsProfileDescription =>
      'Join match rooms, see match %, and Connect when both sides are ready.';

  @override
  String get floMeetsOpenOnCampusMap => 'Open on campus map';

  @override
  String get floMeetsPreviewDemoMatch => 'Preview demo match';

  @override
  String floMeetsDiscoverChip(String time) {
    return 'Flo Meet at $time';
  }

  @override
  String get floMeetsHubRooms => 'Rooms';

  @override
  String get floMeetsHubWaiting => 'Waiting';

  @override
  String get floMeetsHubMatches => 'Matches';

  @override
  String get floMeetsRoomsEmpty =>
      'No published match rooms yet. Check back soon.';

  @override
  String get floMeetsWaitingEmpty =>
      'No waiting connections. Connect with someone in a room to see them here.';

  @override
  String get floMeetsMatchesEmpty =>
      'No matches yet. Connect in a room — a match appears when both sides Connect.';

  @override
  String get floMeetsJoinedBadge => 'Joined';

  @override
  String floMeetsOccupancy(int current, int capacity) {
    return '$current / $capacity people';
  }

  @override
  String get floMeetsJoinRoom => 'Join room';

  @override
  String get floMeetsLeaveRoom => 'Leave room';

  @override
  String get floMeetsRoomFull => 'This room is full';

  @override
  String get floMeetsRoomNotFound => 'Room not found';

  @override
  String get floMeetsBackToHub => 'Back to Meets';

  @override
  String get floMeetsBackToRoom => 'Back to room';

  @override
  String get floMeetsPeopleInRoom => 'People in this room';

  @override
  String get floMeetsNoPeopleInRoom => 'No one else in this room yet.';

  @override
  String floMeetsMatchPercent(int percent) {
    return '$percent% match';
  }

  @override
  String get floMeetsMatchWindowTitle => 'Match window';

  @override
  String get floMeetsPartnerNotFound => 'Partner not found in this room';

  @override
  String get floMeetsOverlapTitle => 'Shared interests';

  @override
  String get floMeetsConnectCta => 'Connect';

  @override
  String get floMeetsConnecting => 'Connecting…';

  @override
  String get floMeetsWaitingForThem => 'Waiting for them…';

  @override
  String get floMeetsMatchedLabel => 'Matched';

  @override
  String get floMeetsMatchedContinue => 'View meet details';

  @override
  String get floMeetsOpenConnectShare => 'Open Connect share';

  @override
  String get consentFloMeetsBody =>
      'Flo Meets stores your meet nickname, amenity meet point, and optional contact locally. Update preferences anytime from Profile or Meets.';

  @override
  String get consentFloMeetsBullet => 'Flo Meets uses nickname-only reveal.';
}
