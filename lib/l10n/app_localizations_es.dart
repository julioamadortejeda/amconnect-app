// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get commonLoading => 'Cargando...';

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
  String get fieldFullName => 'Nombre completo';

  @override
  String get fieldPhone => 'Teléfono';

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
  String get shellHome => 'Inicio';

  @override
  String get shellAgenda => 'Agenda';

  @override
  String get shellClients => 'Clientes';

  @override
  String get shellData => 'Datos';

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
  String get clientsEmpty => 'Sin clientes registrados';

  @override
  String get clientsError => 'Error al cargar clientes';

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
  String get clientsNoteTypePdf => 'Documento PDF';

  @override
  String get clientsNoteTypeAudio => 'Nota de voz';

  @override
  String get clientsNoteTypeImage => 'Imagen';

  @override
  String get clientsNoteTypeText => 'WhatsApp';

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
  String get remindersFilterDeleted => 'Eliminados';

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
  String get remindersVoiceHint => 'DÍSELO CON TUS PALABRAS';

  @override
  String get remindersVoicePlaceholder =>
      'recuérdame llamar a José mañana a las 3';

  @override
  String get remindersFieldTitle => 'Título';

  @override
  String get remindersFieldType => 'Tipo';

  @override
  String get remindersFieldClient => 'Cliente';

  @override
  String get remindersFieldDate => 'Fecha';

  @override
  String get remindersFieldTime => 'Hora';

  @override
  String get remindersRepeatYearly => 'Repetir cada año';

  @override
  String get remindersCreateBtn => 'Crear recordatorio';

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
  String get voiceChatSkillActive => 'Consultando datos…';

  @override
  String get chatTitle => 'Asistente';

  @override
  String get chatSubtitle => 'Conectado a tu base';

  @override
  String get chatNewConversation => 'Nueva conversación';

  @override
  String get chatInputHint => 'Pregúntale a tu asistente…';

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
  String get feedViewModeIngest => 'Ingestar';

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
  String get feedPreviewTitle => 'Confirmar archivo';

  @override
  String get feedPreviewConfirm => 'Confirmar';

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
  String get remindersDetailNotes => 'Notas';

  @override
  String get remindersDetailNoNotes => 'Sin notas';

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
  String get remindersDetailTomorrow => 'Mañana';

  @override
  String remindersDetailDaysLeft(int count) {
    return '${count}d';
  }

  @override
  String remindersDetailDaysOverdue(int count) {
    return '${count}d venc.';
  }
}
