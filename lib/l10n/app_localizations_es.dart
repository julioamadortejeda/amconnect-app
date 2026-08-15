// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'AMConnect Advisor';

  @override
  String get commonTerms =>
      'Al continuar, aceptas los Términos y la Política de Privacidad.';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonAccount => 'Cuenta';

  @override
  String get commonSignOut => 'Cerrar sesión';

  @override
  String get commonYesterday => 'Ayer';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonOpenSettings => 'Abrir Ajustes';

  @override
  String get homeEmptyPendientes => 'Sin recordatorios pendientes';

  @override
  String get homeEmptySeguimientos => 'Sin seguimientos activos';

  @override
  String get homeEmptyClientes => 'Aún no tienes clientes registrados';

  @override
  String homeViewAllCount(int count) {
    return 'Ver todos ($count)';
  }

  @override
  String get loginWelcomeTitle => 'Bienvenido a\nAMConnect';

  @override
  String get loginWelcomeSubtitle =>
      'Tu asistente inteligente. Concentra a tus clientes, pólizas y recordatorios — y pregúntale lo que sea.';

  @override
  String get loginContinueApple => 'Continuar con Apple';

  @override
  String get loginContinueGoogle => 'Continuar con Google';

  @override
  String get loginEnterEmail => 'Entrar con correo';

  @override
  String get loginGuest => 'Explorar como invitado';

  @override
  String get loginErrGoogle => 'No se pudo iniciar sesión con Google.';

  @override
  String get loginErrApple => 'No se pudo iniciar sesión con Apple.';

  @override
  String get emailLoginTitle => 'Iniciar sesión';

  @override
  String get emailLoginSubtitle => 'Ingresa con tu correo y contraseña';

  @override
  String get emailLoginForgot => '¿Olvidaste tu contraseña?';

  @override
  String get emailLoginBtn => 'Iniciar sesión';

  @override
  String get emailLoginNoAccount => '¿No tienes cuenta? ';

  @override
  String get emailLoginCreateAccount => 'Crear cuenta';

  @override
  String get forgotPasswordTitle => 'Recupera tu acceso';

  @override
  String get forgotPasswordSubtitleEmail =>
      'Ingresa tu correo y te mandamos un código para restablecer tu contraseña.';

  @override
  String get forgotPasswordSubtitleReset =>
      'Ingresa el código que te enviamos y tu nueva contraseña.';

  @override
  String forgotPasswordCodeSentTo(String email) {
    return 'Enviamos un código a $email';
  }

  @override
  String get forgotPasswordSendCodeBtn => 'Enviar código';

  @override
  String get forgotPasswordResetBtn => 'Restablecer contraseña';

  @override
  String get forgotPasswordBackToEmail => 'Usar otro correo';

  @override
  String get forgotPasswordSuccessTitle => 'Contraseña actualizada';

  @override
  String get forgotPasswordSuccessMsg =>
      'Ya puedes iniciar sesión con tu nueva contraseña.';

  @override
  String get forgotPasswordSuccessBtn => 'Iniciar sesión';

  @override
  String get errRequestCodeFailed =>
      'No pudimos enviar el código. Intenta de nuevo.';

  @override
  String get errInvalidCode => 'El código no es válido o ya expiró.';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerSubtitle => 'Regístrate para comenzar a usar AMConnect';

  @override
  String get registerBtn => 'Crear cuenta';

  @override
  String get registerHasAccount => '¿Ya tienes cuenta? ';

  @override
  String get registerSignIn => 'Iniciar sesión';

  @override
  String get fieldEmail => 'Correo electrónico';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get fieldConfirm => 'Confirmar contraseña';

  @override
  String get fieldCode => 'Código de verificación';

  @override
  String get fieldFullName => 'Nombre completo';

  @override
  String get fieldPhone => 'Teléfono';

  @override
  String get fieldOccupation => 'Ocupación';

  @override
  String get fieldAddress => 'Dirección';

  @override
  String get fieldBirthdate => 'Fecha de nacimiento';

  @override
  String get fieldRfc => 'RFC';

  @override
  String get fieldCurp => 'CURP';

  @override
  String get fieldNotes => 'Notas';

  @override
  String get accountProfileTitle => 'Perfil';

  @override
  String get accountPlanTitle => 'Tu plan';

  @override
  String get accountEdit => 'Editar';

  @override
  String get accountSave => 'Guardar';

  @override
  String get accountSaved => 'Cambios guardados';

  @override
  String get accountErrSave =>
      'No se pudieron guardar los cambios. Inténtalo de nuevo.';

  @override
  String accountPlanPrice(String price) {
    return '$price MXN/mes';
  }

  @override
  String get accountPlanStatusTrial => 'Prueba';

  @override
  String get accountPlanStatusActive => 'Activo';

  @override
  String get accountPlanStatusExpired => 'Expirado';

  @override
  String get accountPlanStatusCancelled => 'Cancelado';

  @override
  String accountTrialDaysLeft(int count) {
    return '$count días restantes de prueba';
  }

  @override
  String get accountUsageChatLabel => 'Mensajes de chat';

  @override
  String get accountUsageIngestionsLabel => 'Documentos procesados';

  @override
  String accountUsageFormat(int used, int limit) {
    return '$used de $limit';
  }

  @override
  String get accountSignOutTitle => '¿Cerrar sesión?';

  @override
  String get accountSignOutMessage =>
      'Podrás volver a iniciar sesión cuando quieras.';

  @override
  String get accountAppearanceTitle => 'Apariencia';

  @override
  String get themeModeSystem => 'Automático';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get accountHelpTitle => 'Ayuda';

  @override
  String get accountHelp => 'Ayuda y soporte';

  @override
  String get accountNotificationsDisabled => 'Notificaciones desactivadas';

  @override
  String get errInvalidEmail => 'Ingresa un correo electrónico válido';

  @override
  String get errEmptyCredentials => 'Por favor, llena todos los campos';

  @override
  String get errWrongCredentials => 'Correo o contraseña incorrectos';

  @override
  String get errFillAll => 'Por favor, completa todos los campos';

  @override
  String get errPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get errCreateAccount =>
      'Error al crear la cuenta. Inténtalo de nuevo.';

  @override
  String get errModelBusy =>
      'El asistente de IA está ocupado en este momento. Por favor, intenta de nuevo en unos segundos.';

  @override
  String get errSessionExpired =>
      'Tu sesión ha expirado. Por favor, vuelve a iniciar sesión.';

  @override
  String get errNotFound => 'Recurso no encontrado.';

  @override
  String get errUnknown =>
      'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.';

  @override
  String get errNetwork =>
      'Error de conexión. Revisa tu internet y vuelve a intentarlo.';

  @override
  String get errQuotaExceeded =>
      'Alcanzaste el límite de tu plan este mes. Actualiza tu plan para continuar.';

  @override
  String get errSubscriptionRequired =>
      'Tu suscripción ha vencido. Activa un plan para continuar.';

  @override
  String get errValidationFailed =>
      'Los datos enviados no son válidos. Revisa la información e intenta de nuevo.';

  @override
  String get errConflict => 'Ya existe un registro con esos datos.';

  @override
  String get errAccessDenied => 'No tienes permiso para realizar esta acción.';

  @override
  String get errAiFailed =>
      'El asistente tuvo un problema al procesar tu solicitud. Intenta de nuevo.';

  @override
  String get errUploadFailed =>
      'No se pudo subir el archivo. Intenta de nuevo.';

  @override
  String get errSharedFileMissing =>
      'El archivo compartido ya no está disponible. Compártelo de nuevo.';

  @override
  String get errSharedTextTooLarge =>
      'El texto es demasiado largo para procesarlo. Comparte un chat más corto o solo los mensajes relevantes.';

  @override
  String get errSpeechUnavailable =>
      'El dictado por voz no está disponible en este dispositivo. Escribe tu mensaje.';

  @override
  String errRefCode(String ref) {
    return 'Código de referencia: $ref';
  }

  @override
  String get errFilePickerTimeout =>
      'La selección de archivo tardó demasiado. Intenta de nuevo.';

  @override
  String get errFilePickerOpen => 'No se pudo abrir el selector de archivos.';

  @override
  String get errFilePathUnavailable =>
      'No se pudo obtener la ruta del archivo seleccionado.';

  @override
  String get errFileOpenFailed =>
      'No se pudo abrir el archivo. Intenta de nuevo.';

  @override
  String get shellHome => 'Inicio';

  @override
  String get shellAgenda => 'Agenda';

  @override
  String get shellClients => 'Cartera';

  @override
  String get shellData => 'Datos';

  @override
  String get analyticsTitle => 'Estadísticas de Cartera';

  @override
  String get analyticsFunnelTitle => 'Embudo de Prospección';

  @override
  String get analyticsFunnelProspects => 'Prospectos';

  @override
  String get analyticsFunnelClients => 'Clientes con póliza';

  @override
  String get analyticsFunnelRate => 'Tasa de cierre';

  @override
  String get analyticsPolicyStatus => 'Estatus de Renovación';

  @override
  String get analyticsPolicyActive => 'Vigentes';

  @override
  String get analyticsPolicyExpired => 'Vencidas / Por Renovar';

  @override
  String get analyticsPolicyPending => 'En Trámite';

  @override
  String get analyticsBranchDist => 'Diversificación por Ramo';

  @override
  String get analyticsCarrierDist => 'Distribución por Aseguradora';

  @override
  String get homeNotificationsBannerTitle => 'Notificaciones desactivadas';

  @override
  String get homeNotificationsBannerSubtitle =>
      'Actívalas para no perderte tus recordatorios';

  @override
  String get homeTitle => 'AMConnect';

  @override
  String homeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeGreetingDefault => '¡Hola! Buen día';

  @override
  String get homeImmediateAttention => 'Atención inmediata';

  @override
  String get homePortfolio => 'Tu cartera';

  @override
  String get homeNeedAttention => 'Necesitan atención';

  @override
  String get homeAiHint => 'Pregúntale sobre tus clientes';

  @override
  String homeUrgentCount(int count) {
    return '$count urgente(s)';
  }

  @override
  String homeUrgentToday(int count) {
    return '$count urgente(s) · hoy';
  }

  @override
  String homeAttentionDesc(int count) {
    return '$count póliza(s) necesitan tu atención';
  }

  @override
  String get homePolicies => 'Pólizas';

  @override
  String get homeToRenew => 'Por renovar';

  @override
  String get homeClients => 'Clientes';

  @override
  String get homePendientes => 'Pendientes';

  @override
  String get homeSeguimientos => 'Seguimientos';

  @override
  String get homeClientesRecientes => 'Clientes recientes';

  @override
  String get homeViewAgenda => 'Ver agenda';

  @override
  String get homeViewAll => 'Ver todos';

  @override
  String get currencyMXN => 'Peso Mexicano';

  @override
  String get currencyUSD => 'Dólar Americano';

  @override
  String get paymentMethodDirectDebit => 'Domiciliación';

  @override
  String get paymentMethodBankTransfer => 'Transferencia Bancaria';

  @override
  String get paymentMethodCheck => 'Cheque';

  @override
  String get paymentMethodCash => 'Efectivo';

  @override
  String get paymentMethodCreditCard => 'Tarjeta de Crédito';

  @override
  String get paymentFrequencyMonthly => 'Mensual';

  @override
  String get paymentFrequencyQuarterly => 'Trimestral';

  @override
  String get paymentFrequencySemiannual => 'Semestral';

  @override
  String get paymentFrequencyAnnual => 'Anual';

  @override
  String get participantRoleHolder => 'Titular';

  @override
  String get participantRoleInsured => 'Asegurado';

  @override
  String get participantRolePolicyholder => 'Contratante';

  @override
  String get participantRoleDependent => 'Dependiente';

  @override
  String get policyStatusActive => 'Vigente';

  @override
  String get policyStatusCancelled => 'Cancelada';

  @override
  String get policyStatusExpired => 'Vencida';

  @override
  String get policyStatusPending => 'Pendiente';

  @override
  String get policyStatusSuspended => 'Suspendida';

  @override
  String get reminderStatusCreated => 'Creado';

  @override
  String get reminderStatusInProgress => 'En Proceso';

  @override
  String get reminderStatusDone => 'Completado';

  @override
  String get reminderStatusCancelled => 'Cancelado';

  @override
  String get reminderStatusPaused => 'En Pausa';

  @override
  String get reminderTypePayment => 'Pago';

  @override
  String get reminderTypeRenewal => 'Renovación';

  @override
  String get reminderTypeCancellation => 'Cancelación';

  @override
  String get reminderTypeFollowUp => 'Seguimiento';

  @override
  String get reminderTypeCall => 'Llamada';

  @override
  String get reminderTypeAppointment => 'Cita';

  @override
  String get reminderTypeAnniversary => 'Aniversario de Póliza';

  @override
  String get reminderTypeOther => 'Otro';

  @override
  String get clientsTitle => 'Clientes';

  @override
  String clientsTotal(int count) {
    return '$count en total';
  }

  @override
  String get clientsSearchHint => 'Buscar cliente…';

  @override
  String get clientsTabClients => 'Clientes';

  @override
  String get clientsTabPolicies => 'Pólizas';

  @override
  String get clientsSearchPolicyHint =>
      'Buscar póliza, aseguradora o producto…';

  @override
  String get clientsEmptyPolicies => 'Sin pólizas en cartera';

  @override
  String get clientsErrorPolicies => 'Error al cargar pólizas';

  @override
  String get clientsEmpty => 'Sin clientes registrados';

  @override
  String get clientsError => 'Error al cargar clientes';

  @override
  String get clientsDeleteTitle => '¿Eliminar cliente?';

  @override
  String get clientsDeleteMessage =>
      'Se eliminará este cliente y no aparecerá más en tu cartera. Esta acción no se puede deshacer.';

  @override
  String get clientsErrDelete =>
      'No se pudo eliminar el cliente. Intenta de nuevo.';

  @override
  String get clientsErrAddNote =>
      'No se pudo agregar la nota. Intenta de nuevo.';

  @override
  String get clientsContactSection => 'Contacto';

  @override
  String get clientsNoPolicies => 'Sin pólizas registradas';

  @override
  String get clientsNoNotes => 'Sin notas';

  @override
  String get clientsStatusProspect => 'Prospecto';

  @override
  String get clientsStatusToRenew => 'Por renovar';

  @override
  String get clientsStatusPaymentDue => 'Pago próximo';

  @override
  String get clientsStatusUpToDate => 'Al día';

  @override
  String clientsAge(int count) {
    return '$count años';
  }

  @override
  String clientsMemberSince(int year) {
    return 'Cliente desde $year';
  }

  @override
  String get clientsNewClient => 'Cliente';

  @override
  String get clientsNewTitle => 'Nuevo cliente';

  @override
  String get clientsEditTitle => 'Editar cliente';

  @override
  String get clientsCreateBtn => 'Crear cliente';

  @override
  String get clientsCreated => 'Cliente creado';

  @override
  String get clientsUpdated => 'Cliente actualizado';

  @override
  String get clientsFieldNoBirthdate => 'Sin fecha';

  @override
  String get clientsFieldInvalidPhone =>
      'Ingresa un teléfono válido (10 a 15 dígitos)';

  @override
  String get clientsSectionPersonal => 'Datos personales';

  @override
  String get clientsSectionFiscal => 'Fiscal';

  @override
  String get clientsFieldGeneralNotes => 'Notas generales';

  @override
  String get clientsAddNote => 'Agregar nota rápida';

  @override
  String get clientsAddNoteHint => 'Escribe una nota sobre este cliente…';

  @override
  String get clientsNoteTypePdf => 'Documento PDF';

  @override
  String get clientsNoteTypeAudio => 'Nota de voz';

  @override
  String get clientsNoteTypeImage => 'Imagen';

  @override
  String get clientsNoteTypeText => 'Nota';

  @override
  String get clientsNoteTypeWhatsapp => 'WhatsApp';

  @override
  String get clientsNoteOpenFile => 'Ver archivo';

  @override
  String get clientsActionCall => 'Llamar';

  @override
  String get clientsActionMessage => 'Mensaje';

  @override
  String get clientsActionRemind => 'Recordar';

  @override
  String get clientsActionUpload => 'Subir';

  @override
  String get clientsActionAsk => 'Preguntar';

  @override
  String get clientsActionNoPhone =>
      'Este cliente no tiene teléfono registrado';

  @override
  String get clientsActionLaunchError => 'No se pudo abrir la aplicación';

  @override
  String get clientsActionInvalidPhone =>
      'El teléfono de este cliente no es válido';

  @override
  String clientsPoliciesTab(int count) {
    return 'Pólizas · $count';
  }

  @override
  String clientsNotesTab(int count) {
    return 'Notas · $count';
  }

  @override
  String get clientsPolicyActive => 'Vigente';

  @override
  String get clientsPolicySumInsured => 'Suma asegurada';

  @override
  String get clientsPolicyPremium => 'Prima';

  @override
  String get clientsPolicyNextPayment => 'Próximo pago';

  @override
  String get clientsPolicyDeductible => 'Deducible';

  @override
  String get clientsPolicyEndDate => 'Vencimiento';

  @override
  String get clientsPolicyFiles => 'Archivos';

  @override
  String get clientsPolicyFileObsolete => 'Obsoleto';

  @override
  String clientsPolicyOldVersions(int count) {
    return 'Versiones anteriores ($count)';
  }

  @override
  String get clientsPolicyDeleteNoteTitle => 'Eliminar archivo';

  @override
  String get clientsPolicyDeleteNoteMsg =>
      'Esta versión ya no está activa. ¿Deseas eliminarla?';

  @override
  String clientsAskAbout(String name) {
    return 'Preguntar sobre $name';
  }

  @override
  String get remindersAskAbout => 'Preguntar sobre esto';

  @override
  String get remindersTitle => 'Agenda';

  @override
  String remindersPendingCount(int count) {
    return '$count pendientes';
  }

  @override
  String get remindersFilterAll => 'Todos';

  @override
  String get remindersFilterPayments => 'Pagos';

  @override
  String get remindersFilterRenewals => 'Renovaciones';

  @override
  String get remindersFilterCalls => 'Llamadas';

  @override
  String get remindersFilterCompleted => 'Completados';

  @override
  String get remindersFilterDeleted => 'Eliminados';

  @override
  String get remindersFilterSelectTitle => 'Filtrar por';

  @override
  String get remindersCalendarHistoryLabel => 'Historial';

  @override
  String get remindersGroupOverdue => 'Vencidos';

  @override
  String get remindersGroupThisWeek => 'Resto de la semana';

  @override
  String get remindersGroupLater => 'Más adelante';

  @override
  String get remindersDeletedWarning =>
      'Los recordatorios eliminados no pueden restaurarse.';

  @override
  String get remindersEmpty => 'Sin recordatorios para mostrar';

  @override
  String get remindersError => 'Error al cargar recordatorios';

  @override
  String get calendarToday => 'Hoy';

  @override
  String get calendarSun => 'D';

  @override
  String get calendarMon => 'L';

  @override
  String get calendarTue => 'M';

  @override
  String get calendarWed => 'M';

  @override
  String get calendarThu => 'J';

  @override
  String get calendarFri => 'V';

  @override
  String get calendarSat => 'S';

  @override
  String get remindersNewTitle => 'Nuevo recordatorio';

  @override
  String get remindersCreated => 'Recordatorio creado';

  @override
  String get remindersSectionInfo => 'Información';

  @override
  String get remindersSectionDetails => 'Detalles';

  @override
  String get remindersVoiceHint => 'DÍSELO CON TUS PALABRAS';

  @override
  String get remindersVoicePlaceholder =>
      'recuérdame llamar a José mañana a las 3';

  @override
  String get remindersFieldTitle => 'Título';

  @override
  String get remindersFieldDescription => 'Descripción';

  @override
  String get remindersFieldType => 'Tipo';

  @override
  String get remindersFieldClient => 'Cliente';

  @override
  String get remindersFieldDate => 'Fecha';

  @override
  String get remindersFieldTime => 'Hora';

  @override
  String get remindersFieldDateTime => 'Fecha y hora';

  @override
  String get remindersRepeatYearly => 'Repetir cada año';

  @override
  String get remindersCreateBtn => 'Crear recordatorio';

  @override
  String get remindersSelectClientTitle => 'Seleccionar cliente';

  @override
  String get remindersNoClientOption => 'Sin cliente';

  @override
  String get remindersSelectPolicyTitle => 'Seleccionar póliza';

  @override
  String get remindersNoPolicyOption => 'Sin póliza';

  @override
  String get remindersSelectStatusTitle => 'Seleccionar estado';

  @override
  String get remindersPolicyNeedsClient => 'Elige un cliente primero';

  @override
  String get remindersPickDateTitle => 'Fecha y hora del recordatorio';

  @override
  String get remindersPickDateMessage =>
      'Elige cuándo quieres que te recuerde esto.';

  @override
  String get voiceListening => 'Escuchando…';

  @override
  String get voiceTapToClose => 'Toca para cerrar';

  @override
  String get voiceInputHint => 'Pregunta…';

  @override
  String get voiceSend => 'Enviar';

  @override
  String get voiceTapToSend => 'Toca para enviar';

  @override
  String get voiceTapToStart => 'Toca para hablar';

  @override
  String get voiceNotAvailable => 'Voz no disponible';

  @override
  String get voiceChatConnecting => 'Conectando…';

  @override
  String get voiceChatSessionReady => 'Preparando sesión…';

  @override
  String get voiceChatListening => 'Escuchando…';

  @override
  String get voiceChatModelSpeaking => 'Respondiendo…';

  @override
  String get voiceChatEnd => 'Terminar sesión';

  @override
  String get voiceChatClosed => 'Sesión terminada';

  @override
  String get voiceChatError => 'Error de conexión';

  @override
  String get voiceChatPermissionDenied => 'Permiso de micrófono denegado';

  @override
  String get voiceOpenSettingsHint => 'Toca para abrir Ajustes';

  @override
  String get voiceChatSkillActive => 'Consultando datos…';

  @override
  String get voiceChatThinking => 'Pensando…';

  @override
  String get voiceOutputTitle => 'Salida de audio';

  @override
  String get voiceOutputSpeaker => 'Altavoz del teléfono';

  @override
  String get voiceOutputBluetooth => 'Dispositivo Bluetooth';

  @override
  String get voiceOutputWired => 'Audífonos con cable';

  @override
  String get voiceOutputOther => 'Otro dispositivo';

  @override
  String get voiceOutputNone => 'No hay dispositivos de audio disponibles';

  @override
  String get voiceSkillSearchingContacts => 'Buscando cliente…';

  @override
  String get voiceSkillReviewingContacts => 'Revisando tus clientes…';

  @override
  String get voiceSkillSavingContact => 'Actualizando cliente…';

  @override
  String get voiceSkillSearchingNotes => 'Buscando en tus notas…';

  @override
  String get voiceSkillSavingNote => 'Guardando nota…';

  @override
  String get voiceSkillSearchingPolicies => 'Buscando póliza…';

  @override
  String get voiceSkillReviewingPolicies => 'Revisando tus pólizas…';

  @override
  String get voiceSkillSavingPolicy => 'Guardando póliza…';

  @override
  String get voiceSkillSearchingReminders => 'Buscando recordatorios…';

  @override
  String get voiceSkillSavingReminder => 'Actualizando recordatorio…';

  @override
  String get voiceSkillCatalog => 'Consultando catálogo…';

  @override
  String get voiceSkillSavingCatalog => 'Guardando en catálogo…';

  @override
  String get voiceSkillPendingTask => 'Anotando pendiente…';

  @override
  String get voiceSkillKnowledge => 'Buscando en tu base de conocimiento…';

  @override
  String get assistantVoiceActive => 'Voz activa';

  @override
  String get chatTitle => 'Asistente';

  @override
  String get chatBackendFree => 'Free';

  @override
  String get chatBackendEnterprise => 'Enterprise';

  @override
  String get chatSubtitle => 'Conectado a tu base';

  @override
  String get chatNewConversation => 'Nueva conversación';

  @override
  String get chatInputHint => 'Pregúntale a tu asistente…';

  @override
  String get chatCardViewProfile => 'Ver Perfil';

  @override
  String get chatCardViewPolicy => 'Ver Póliza';

  @override
  String get chatCardGoToAgenda => 'Ir a Agenda';

  @override
  String get chatCardContactInfoTitle => 'Contacto';

  @override
  String get chatCardContactListTitle => 'Contactos coincidentes';

  @override
  String get chatCardReminderListTitle => 'Recordatorios y pendientes';

  @override
  String get chatCardPolicyInfoTitle => 'Póliza Encontrada';

  @override
  String get chatCardActionCall => 'Llamar';

  @override
  String get chatCardActionWhatsApp => 'WhatsApp';

  @override
  String get feedTitle => 'Base de conocimiento';

  @override
  String get feedSubtitle => 'Alimentar la app';

  @override
  String get feedQuestion => '¿Qué quieres agregar?';

  @override
  String get feedTypePolicyPdf => 'Póliza PDF';

  @override
  String get feedTypePolicyPdfDesc => 'Sube la póliza y la leo completa';

  @override
  String get feedTypePolicyPhoto => 'Foto de póliza';

  @override
  String get feedTypePolicyPhotoDesc => 'Fotografía con tu cámara';

  @override
  String get feedTypeAudio => 'Audio / nota voz';

  @override
  String get feedTypeAudioDesc => 'Transcribe y extrae datos';

  @override
  String get feedAudioSourceTitle => '¿Cómo quieres agregarlo?';

  @override
  String get feedAudioSourceFile => 'Elegir archivo';

  @override
  String get feedAudioSourceFileDesc => 'Sube un audio ya grabado';

  @override
  String get feedAudioSourceRecord => 'Grabar audio';

  @override
  String get feedAudioSourceRecordDesc => 'Graba una nota de voz ahora';

  @override
  String get feedRecorderTitle => 'Grabar nota de voz';

  @override
  String get feedRecorderTapToStart => 'Toca el botón para empezar a grabar';

  @override
  String get feedRecorderRecording => 'Grabando…';

  @override
  String get feedRecorderReady => 'Lista para enviar';

  @override
  String get feedRecorderPlaying => 'Reproduciendo…';

  @override
  String get feedRecorderPlay => 'Reproducir';

  @override
  String get feedRecorderPause => 'Pausar';

  @override
  String get feedRecorderDiscard => 'Descartar';

  @override
  String get feedRecorderAccept => 'Aceptar';

  @override
  String get feedRecorderPermissionDenied =>
      'Necesitamos acceso al micrófono para grabar. Actívalo en los ajustes del dispositivo.';

  @override
  String get feedRecorderOpenSettings => 'Abrir ajustes';

  @override
  String get feedTypeText => 'Texto / notas';

  @override
  String get feedTypeTextDesc => 'Pega chats o notas escritas';

  @override
  String get feedTypeWhatsapp => 'Importar chat de WhatsApp';

  @override
  String get feedTypeWhatsappDesc => 'Exporta y sube la conversación';

  @override
  String get feedTypeKnowledgeImage => 'Imagen / captura';

  @override
  String get feedTypeKnowledgeImageDesc => 'Foto, captura de pantalla o imagen';

  @override
  String get feedTypeDocument => 'PDF de conocimiento';

  @override
  String get feedTypeDocumentDesc => 'Documento, manual, contrato…';

  @override
  String get feedRecentlyUploaded => 'Subido recientemente';

  @override
  String get feedUploading => 'Subiendo archivo…';

  @override
  String get feedProcessing => 'Procesando con IA…';

  @override
  String get feedUploadingDesc => 'Enviando el PDF a Supabase Storage';

  @override
  String get feedProcessingDesc =>
      'La IA está extrayendo los datos de la póliza';

  @override
  String get feedStepGettingUrl => 'Obteniendo enlace de subida…';

  @override
  String get feedStepUploading => 'Subiendo archivo al servidor…';

  @override
  String get feedStepProcessing => 'Procesando archivo con IA…';

  @override
  String get feedViewModeIngest => 'Cargar';

  @override
  String get feedViewModeKnowledge => 'Conocimiento';

  @override
  String get feedStatsPDFs => 'PDFs';

  @override
  String get feedStatsImages => 'Imágenes';

  @override
  String get feedStatsAudios => 'Audios';

  @override
  String get feedStatsNotes => 'Notas';

  @override
  String get feedStatsChats => 'Chats';

  @override
  String get feedSearchHint => 'Buscar en base de conocimiento...';

  @override
  String get feedSearchNoResults => 'No se encontraron notas o documentos.';

  @override
  String get feedStatsTitle => 'Resumen de conocimiento';

  @override
  String get feedAllNotesTitle => 'Todas las notas';

  @override
  String get feedSuccessTitle => 'Póliza creada';

  @override
  String get feedSuccessUpdateTitle => 'Póliza actualizada';

  @override
  String feedSuccessFieldsSaved(int count) {
    return '$count datos guardados';
  }

  @override
  String get feedSuccessNewOne => '1 recordatorio nuevo';

  @override
  String feedSuccessNewMany(int count) {
    return '$count recordatorios nuevos';
  }

  @override
  String get feedSuccessExistingOne => '1 ya existía';

  @override
  String feedSuccessExistingMany(int count) {
    return '$count ya existían';
  }

  @override
  String get feedSuccessRemindersSection => 'RECORDATORIOS';

  @override
  String get feedSuccessReminderNew => 'Nuevo';

  @override
  String get feedSuccessReminderExisting => 'Ya existía';

  @override
  String get feedSuccessDone => 'Listo';

  @override
  String get feedKnowledgeSuccessTitle => '¡Guardado!';

  @override
  String get feedKnowledgeDone => 'Cerrar';

  @override
  String get feedTextInputTitle => 'Agregar nota o texto';

  @override
  String get feedWhatsappInputTitle => 'Importar conversación';

  @override
  String get feedTextInputHint => 'Pega aquí el texto, notas o conversación…';

  @override
  String get feedTextInputSubmit => 'Procesar';

  @override
  String get feedConfirmPolicyTitle => 'Confirmar póliza';

  @override
  String get feedPreviewTitle => 'Confirmar archivo';

  @override
  String get feedPreviewConfirm => 'Confirmar';

  @override
  String get feedIngestConfirmCta => 'Sí, guardar';

  @override
  String get feedIngestCorrectCta => 'Corregir / Chatear';

  @override
  String get feedIngestCancelCta => 'Cancelar';

  @override
  String get feedIngestHolderLabel => 'Contratante';

  @override
  String get feedIngestCarrierLabel => 'Aseguradora';

  @override
  String get feedIngestBranchProductLabel => 'Ramo / Prod.';

  @override
  String get feedIngestPolicyNumberLabel => 'Nº Póliza';

  @override
  String get feedIngestPremiumLabel => 'Prima';

  @override
  String get feedIngestValidityLabel => 'Vigencia';

  @override
  String get feedContactMismatchTitle => '¿A quién asignamos esta póliza?';

  @override
  String feedContactMismatchBody(String detectedName, String screenName) {
    return 'El documento indica que el titular es $detectedName, pero estás en la pantalla de $screenName.';
  }

  @override
  String feedContactMismatchAssignCta(String screenName) {
    return 'Sí, asignar a $screenName';
  }

  @override
  String feedContactMismatchUseDetectedCta(String detectedName) {
    return 'No, usar $detectedName';
  }

  @override
  String feedContactMismatchResolvedBanner(
      String screenName, String detectedName) {
    return 'Esta póliza se asignará a $screenName. El documento identificaba a $detectedName como titular.';
  }

  @override
  String get remindersActionDone => 'Finalizar';

  @override
  String get remindersActionInProgress => 'En proceso';

  @override
  String get remindersActionReschedule => 'Reagendar';

  @override
  String get remindersActionCancel => 'Cancelar';

  @override
  String get remindersActionCancelTitle => 'Cancelar recordatorio';

  @override
  String get remindersActionCancelHint => '¿Por qué se cancela?';

  @override
  String get remindersActionCancelBtn => 'Confirmar cancelación';

  @override
  String get remindersActionCommentRequired =>
      'El comentario es obligatorio para cancelar';

  @override
  String get remindersConfirmDoneTitle => 'Completar Recordatorio';

  @override
  String get remindersConfirmDoneMessage =>
      '¿Estás seguro de que deseas marcar este recordatorio como completado?';

  @override
  String get remindersConfirmDoneBtn => 'Completar';

  @override
  String get remindersConfirmCancelBtn => 'Cancelar';

  @override
  String get remindersConfirmInProgressTitle => 'Marcar en Progreso';

  @override
  String get remindersConfirmInProgressMessage =>
      '¿Deseas marcar este recordatorio como \"En Progreso\"?';

  @override
  String get remindersConfirmInProgressBtn => 'Aceptar';

  @override
  String get remindersRescheduleTitle => 'Reprogramar Recordatorio';

  @override
  String get remindersRescheduleMessage =>
      'Selecciona la nueva fecha y hora para realizar esta tarea.';

  @override
  String get remindersRescheduleSave => 'Guardar';

  @override
  String get remindersFieldDateUpper => 'FECHA';

  @override
  String get remindersFieldTimeUpper => 'HORA';

  @override
  String get remindersCancelTitle => 'Cancelar Recordatorio';

  @override
  String get remindersCancelHint => 'Escribe el motivo de la cancelación...';

  @override
  String get remindersCancelConfirmBtn => 'Confirmar';

  @override
  String get remindersDetailTitle => 'Recordatorio';

  @override
  String get remindersDetailEdit => 'Editar';

  @override
  String get remindersDetailSave => 'Guardar';

  @override
  String get remindersDetailNoClient => 'Sin cliente asignado';

  @override
  String get remindersDetailSaved => 'Cambios guardados';

  @override
  String get remindersDetailStatus => 'Estado';

  @override
  String get remindersDetailDatetime => 'Fecha y hora';

  @override
  String get remindersDetailActions => 'Acciones';

  @override
  String get reminderPriorityUrgent => 'Urgente';

  @override
  String get reminderPriorityWarning => 'Pronto';

  @override
  String get reminderPriorityNormal => 'Normal';

  @override
  String get remindersDetailDueDate => 'Fecha límite';

  @override
  String get remindersDetailCreatedAt => 'Creado el';

  @override
  String get remindersDetailPolicy => 'Póliza';

  @override
  String get remindersDetailSelectType => 'Tipo de recordatorio';

  @override
  String get remindersDetailSelectStatus => 'Estado del recordatorio';

  @override
  String get remindersDetailComments => 'Comentarios';

  @override
  String get remindersDetailNoComments => 'Sin comentarios';

  @override
  String get remindersDetailNoDescription => 'Sin descripción';

  @override
  String get remindersDetailRelations => 'Relaciones';

  @override
  String get remindersDetailAttachments => 'Archivos adjuntos';

  @override
  String get remindersDetailNoAttachments => 'Sin archivos adjuntos';

  @override
  String get remindersDetailTomorrow => 'Mañana';

  @override
  String remindersDetailDaysLeft(int count) {
    return '${count}d';
  }

  @override
  String remindersDetailDaysOverdue(int count) {
    return '${count}d venc.';
  }

  @override
  String get policiesNewPolicyTitle => 'Nueva Póliza';

  @override
  String get policiesPolicyNumber => 'Número de póliza';

  @override
  String get policiesCarrier => 'Aseguradora';

  @override
  String get policiesBranch => 'Ramo';

  @override
  String get policiesProduct => 'Producto';

  @override
  String get policiesStatus => 'Estado';

  @override
  String get policiesCurrency => 'Moneda';

  @override
  String get policiesPaymentFrequency => 'Frecuencia de pago';

  @override
  String get policiesPaymentMethod => 'Método de pago';

  @override
  String get policiesSumInsured => 'Suma asegurada';

  @override
  String get policiesPremium => 'Prima';

  @override
  String get policiesDeductible => 'Deducible';

  @override
  String get policiesStartDate => 'Inicio de vigencia';

  @override
  String get policiesEndDate => 'Fin de vigencia';

  @override
  String get policiesRenewalDate => 'Fecha de renovación';

  @override
  String get policiesNextPaymentDate => 'Siguiente pago';

  @override
  String get policiesNotes => 'Notas';

  @override
  String get policiesSaveBtn => 'Guardar póliza';

  @override
  String get policiesSelectClient => 'Seleccionar cliente';

  @override
  String get policiesCreateCarrier => 'Crear nueva Aseguradora';

  @override
  String get policiesCreateBranch => 'Crear nuevo Ramo';

  @override
  String get policiesCreateProduct => 'Crear nuevo Producto';

  @override
  String get policiesCreatedSuccess => 'Póliza creada con éxito';

  @override
  String get policiesEditPolicyTitle => 'Editar Póliza';

  @override
  String get policiesSaveChangesBtn => 'Guardar cambios';

  @override
  String get policiesUpdatedSuccess => 'Póliza actualizada con éxito';

  @override
  String get policiesDetailTitle => 'Detalle de póliza';

  @override
  String get policiesDetailLoadError => 'No se pudo cargar la póliza.';

  @override
  String get policiesDetailCoverage => 'Cobertura y pago';

  @override
  String get policiesDetailDates => 'Fechas';

  @override
  String get policiesNotesSection => 'Notas';

  @override
  String get policiesEmptyNotes => 'Aún no hay notas para esta póliza.';

  @override
  String get policiesAddNoteHint => 'Escribe una nota...';

  @override
  String get policiesDeleteNoteTitle => 'Eliminar nota';

  @override
  String get policiesDeleteNoteMsg =>
      '¿Deseas eliminar esta nota? Esta acción no se puede deshacer.';

  @override
  String get policiesDeleteTitle => '¿Eliminar póliza?';

  @override
  String get policiesDeleteMessage =>
      'Se eliminará esta póliza y no aparecerá más en tu cartera. Esta acción no se puede deshacer.';

  @override
  String get policiesErrDelete =>
      'No se pudo eliminar la póliza. Intenta de nuevo.';

  @override
  String get policiesErrDeleteNote =>
      'No se pudo eliminar la nota. Intenta de nuevo.';

  @override
  String get policiesErrAddNote =>
      'No se pudo agregar la nota. Intenta de nuevo.';

  @override
  String get policiesAttachFile => 'Adjuntar';

  @override
  String get catalogsTitle => 'Catálogos';

  @override
  String get catalogsTypeCarriers => 'Aseguradoras';

  @override
  String get catalogsTypeBranches => 'Ramos';

  @override
  String get catalogsTypeProducts => 'Productos';

  @override
  String get catalogsSearchHint => 'Buscar...';

  @override
  String get catalogsEmpty => 'No hay resultados';

  @override
  String get catalogsError => 'No se pudieron cargar los catálogos';

  @override
  String get catalogsFieldName => 'Nombre';

  @override
  String get catalogsFieldShortName => 'Nombre corto';

  @override
  String get catalogsFieldCode => 'Código';

  @override
  String get catalogsSelectCarrier => 'Seleccionar aseguradora';

  @override
  String get catalogsSelectBranch => 'Seleccionar ramo';

  @override
  String get catalogsNewCarrierTitle => 'Nueva aseguradora';

  @override
  String get catalogsEditCarrierTitle => 'Editar aseguradora';

  @override
  String get catalogsNewBranchTitle => 'Nuevo ramo';

  @override
  String get catalogsEditBranchTitle => 'Editar ramo';

  @override
  String get catalogsNewProductTitle => 'Nuevo producto';

  @override
  String get catalogsEditProductTitle => 'Editar producto';

  @override
  String get catalogsCreateBtn => 'Crear';

  @override
  String get catalogsCarrierCreated => 'Aseguradora creada';

  @override
  String get catalogsCarrierUpdated => 'Aseguradora actualizada';

  @override
  String get catalogsBranchCreated => 'Ramo creado';

  @override
  String get catalogsBranchUpdated => 'Ramo actualizado';

  @override
  String get catalogsProductCreated => 'Producto creado';

  @override
  String get catalogsProductUpdated => 'Producto actualizado';

  @override
  String get catalogsDeleteTitle => 'Eliminar elemento';

  @override
  String get catalogsDeleteMessage =>
      '¿Seguro que deseas eliminarlo? Esta acción no se puede deshacer.';

  @override
  String get shareTargetTitle => 'Recurso compartido';

  @override
  String get shareTargetSubtitle =>
      'Selecciona a dónde deseas asignar este contenido';

  @override
  String get shareTargetPreview => 'Vista previa';

  @override
  String get shareTargetEmpty => 'No se recibió contenido para procesar';

  @override
  String get shareTargetDestinationPolicyIngest => 'Alta de póliza';

  @override
  String get shareTargetDestinationPolicyIngestSub =>
      'Lectura automática del documento';

  @override
  String get shareTargetPolicyIngestUnavailable =>
      'Solo disponible para PDF o imágenes';

  @override
  String get shareTargetUnsupportedFile =>
      'Este archivo no se puede procesar. Comparte un PDF, una imagen (JPG, PNG, WEBP, GIF), un audio (MP3, WAV, OGG, M4A, WEBM) o un chat exportado en texto (.txt) — las exportaciones con medios adjuntos (.zip) no son compatibles.';

  @override
  String get shareTargetDestinationGlobal =>
      'Ingesta Global (Base de Conocimiento)';

  @override
  String get shareTargetDestinationClient => 'Cliente';

  @override
  String get shareTargetDestinationPolicy => 'Póliza';

  @override
  String get shareTargetDestinationReminder => 'Recordatorio';

  @override
  String get shareTargetNoticePolicyIngest =>
      'Se generará todo en automático: se detecta el cliente, la aseguradora, el producto y las coberturas, y se crean los recordatorios de pago y renovación. Podrás revisar y corregir antes de guardar.';

  @override
  String get shareTargetNoticeGlobal =>
      'Se procesará como nota en tu base de conocimiento general.';

  @override
  String shareTargetNoticeClient(String name) {
    return 'Se procesará como nota en el expediente de $name.';
  }

  @override
  String get shareTargetNoticePickClient =>
      'Elige un cliente para guardar el contenido como nota en su expediente.';

  @override
  String shareTargetNoticePolicy(String policy) {
    return 'Se procesará como nota de la póliza $policy.';
  }

  @override
  String get shareTargetNoticePickPolicy =>
      'Elige una póliza para guardar el contenido como nota suya.';

  @override
  String shareTargetNoticeReminder(String reminder) {
    return 'Se procesará como nota ligada al recordatorio $reminder.';
  }

  @override
  String get shareTargetNoticePickReminder =>
      'Elige un recordatorio para ligarle el contenido como nota.';

  @override
  String get shareTargetActionIngest => 'Cargar recurso';

  @override
  String get shareTargetActionPolicyIngest => 'Procesar póliza';

  @override
  String get shareTargetSelectClient => 'Seleccionar cliente';

  @override
  String get shareTargetSelectPolicy => 'Seleccionar póliza';

  @override
  String get shareTargetSelectReminder => 'Seleccionar recordatorio';

  @override
  String get shareTargetSearchReminderHint => 'Buscar recordatorio…';

  @override
  String get shareTargetPolicyNoNumber => 'Sin número';

  @override
  String get shareTargetCancel => 'Descartar';

  @override
  String get feedMakeGeneral => 'Hacer conocimiento general';

  @override
  String get feedMakeGeneralGlobalDesc =>
      'El archivo estará disponible de forma global para la IA';

  @override
  String get feedMakeGeneralSub =>
      'Activa si deseas que el archivo sea global y no exclusivo de este contexto';

  @override
  String get feedContextAttachReminder => 'Se adjuntará a este recordatorio';

  @override
  String get feedContextAttachPolicy => 'Se adjuntará a esta póliza';

  @override
  String get feedContextAttachClient => 'Se adjuntará a este cliente';

  @override
  String get policiesAskAbout => 'Preguntar sobre esta póliza';

  @override
  String get commonOpenFile => 'Abrir archivo';

  @override
  String get chatCardPolicyListTitle => 'Pólizas en tu portafolio';

  @override
  String get chatCardPolicyCreated => 'Póliza creada';

  @override
  String get chatCardPolicyUpdated => 'Póliza actualizada';

  @override
  String get chatCardFieldHolder => 'Contratante';

  @override
  String get chatCardFieldInsured => 'Asegurado';

  @override
  String get chatCardRemindersLabel => 'Recordatorios';

  @override
  String get chatCardReminderFallback => 'Recordatorio';

  @override
  String get chatCardContactFallback => 'Contacto';

  @override
  String get chatCardFieldPhone => 'Teléfono';

  @override
  String get chatCardFieldEmail => 'Correo';

  @override
  String get chatCardFieldDate => 'Fecha';

  @override
  String get chatCardAttachmentFallback => 'Documento';

  @override
  String get chatSuggestion1 => '¿Quién vence pronto?';

  @override
  String get chatSuggestion2 => '¿Cuánto cobra Javier?';

  @override
  String get chatSuggestion3 => 'Recuérdame llamar mañana';

  @override
  String get chatSuggestion4 => '¿Pagos esta semana?';

  @override
  String chatContextSuggestionContact(String name) {
    return 'Pregúntame lo que quieras sobre **$name**.';
  }

  @override
  String chatContextSuggestionPolicy(String carrier) {
    return 'Pregúntame lo que quieras sobre esta póliza de **$carrier**.';
  }

  @override
  String chatContextSuggestionReminder(String title) {
    return 'Pregúntame lo que quieras sobre este recordatorio: **$title**.';
  }

  @override
  String chatContextSuggestionKnowledge(String fileName) {
    return 'Pregúntame lo que quieras sobre **$fileName**.';
  }

  @override
  String get chatContextSuggestionKnowledgeGeneric =>
      'Pregúntame lo que quieras sobre este documento que subiste.';

  @override
  String get policiesSectionInsuranceDetails => 'Detalles de Seguro';

  @override
  String get policiesSectionParamsPayment => 'Parámetros y Pago';

  @override
  String get policiesSectionAmountsCoverage => 'Montos y Coberturas';

  @override
  String get policiesSectionDatesValidity => 'Fechas de Vigencia y Pago';

  @override
  String get reminderTypeBirthday => 'Cumpleaños';

  @override
  String get reminderSettingsTitle => 'Avisos automáticos';

  @override
  String get reminderSettingsSubtitle => 'Con cuánta anticipación te avisamos';

  @override
  String get reminderSettingsIntro =>
      'La app te avisa sola de pagos, renovaciones, aniversarios y cumpleaños. Aquí eliges con cuánto tiempo.';

  @override
  String get reminderSettingsSameDay => 'El mismo día';

  @override
  String reminderSettingsDaysBefore(int days) {
    return '$days días antes';
  }

  @override
  String get reminderSettingsOff => 'Sin avisos';

  @override
  String get reminderSettingsBranchExceptions => 'Excepciones por ramo';

  @override
  String get reminderSettingsAddException => 'Agregar excepción';

  @override
  String get reminderSettingsAllBranches => 'Todos los ramos';

  @override
  String get reminderSettingsPickDays => 'Anticipación';

  @override
  String get reminderSettingsPickBranch => 'Elige el ramo';

  @override
  String get reminderSettingsNoBranches =>
      'Todavía no tienes ramos en tu catálogo';

  @override
  String get policiesPaymentRule => 'Días de pago';

  @override
  String policiesPaymentMonthly(int day) {
    return 'Cada día $day del mes';
  }

  @override
  String get policiesActivityTitle => 'Actividad';

  @override
  String get policiesActivityUpcoming => 'Próximos';

  @override
  String get policiesActivityHistory => 'Historial';

  @override
  String get policiesActivityEmpty => 'Sin recordatorios para esta póliza';

  @override
  String get reminderSettingsRemoveException => 'Quitar excepción';

  @override
  String get reminderSettingsDefault => 'Todos los demás ramos';

  @override
  String get reminderSettingsHint =>
      'Toca una anticipación para cambiarla. Las excepciones por ramo pisan al valor de arriba.';
}
