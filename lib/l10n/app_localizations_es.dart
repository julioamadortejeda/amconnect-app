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
  String get commonAccount => 'Cuenta';

  @override
  String get commonSignOut => 'Cerrar sesión';

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
  String get reminderTypePayment => 'Pago';

  @override
  String get reminderTypeRenewal => 'Renovación';

  @override
  String get reminderTypeCall => 'Llamada';

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
  String get clientsStatusProspect => 'Prospecto';

  @override
  String get clientsStatusToRenew => 'Por renovar';

  @override
  String get clientsStatusPaymentDue => 'Pago próximo';

  @override
  String get clientsStatusUpToDate => 'Al día';

  @override
  String get clientsActionCall => 'Llamar';

  @override
  String get clientsActionMessage => 'Mensaje';

  @override
  String get clientsActionRemind => 'Recordar';

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
}
