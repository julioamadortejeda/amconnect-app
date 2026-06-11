import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @commonTerms.
  ///
  /// In es, this message translates to:
  /// **'Al continuar, aceptas los Términos y la Política de Privacidad.'**
  String get commonTerms;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get commonAccount;

  /// No description provided for @commonSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get commonSignOut;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a\nAMConnect'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu asistente inteligente. Concentra a tus clientes, pólizas y recordatorios — y pregúntale lo que sea.'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginContinueApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get loginContinueApple;

  /// No description provided for @loginContinueGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginContinueGoogle;

  /// No description provided for @loginEnterEmail.
  ///
  /// In es, this message translates to:
  /// **'Entrar con correo'**
  String get loginEnterEmail;

  /// No description provided for @loginGuest.
  ///
  /// In es, this message translates to:
  /// **'Explorar como invitado'**
  String get loginGuest;

  /// No description provided for @loginErrGoogle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión con Google.'**
  String get loginErrGoogle;

  /// No description provided for @loginErrApple.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión con Apple.'**
  String get loginErrApple;

  /// No description provided for @emailLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get emailLoginTitle;

  /// No description provided for @emailLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa con tu correo y contraseña'**
  String get emailLoginSubtitle;

  /// No description provided for @emailLoginForgot.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get emailLoginForgot;

  /// No description provided for @emailLoginBtn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get emailLoginBtn;

  /// No description provided for @emailLoginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get emailLoginNoAccount;

  /// No description provided for @emailLoginCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get emailLoginCreateAccount;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Regístrate para comenzar a usar AMConnect'**
  String get registerSubtitle;

  /// No description provided for @registerBtn.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerBtn;

  /// No description provided for @registerHasAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get registerHasAccount;

  /// No description provided for @registerSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get registerSignIn;

  /// No description provided for @fieldEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get fieldPassword;

  /// No description provided for @fieldConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get fieldConfirm;

  /// No description provided for @errInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido'**
  String get errInvalidEmail;

  /// No description provided for @errEmptyCredentials.
  ///
  /// In es, this message translates to:
  /// **'Por favor, llena todos los campos'**
  String get errEmptyCredentials;

  /// No description provided for @errWrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get errWrongCredentials;

  /// No description provided for @errFillAll.
  ///
  /// In es, this message translates to:
  /// **'Por favor, completa todos los campos'**
  String get errFillAll;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get errPasswordMismatch;

  /// No description provided for @errCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Error al crear la cuenta. Inténtalo de nuevo.'**
  String get errCreateAccount;

  /// No description provided for @shellHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get shellHome;

  /// No description provided for @shellAgenda.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get shellAgenda;

  /// No description provided for @shellClients.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get shellClients;

  /// No description provided for @shellData.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get shellData;

  /// No description provided for @homeTitle.
  ///
  /// In es, this message translates to:
  /// **'AMConnect'**
  String get homeTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingDefault.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Buen día'**
  String get homeGreetingDefault;

  /// No description provided for @homeImmediateAttention.
  ///
  /// In es, this message translates to:
  /// **'Atención inmediata'**
  String get homeImmediateAttention;

  /// No description provided for @homePortfolio.
  ///
  /// In es, this message translates to:
  /// **'Tu cartera'**
  String get homePortfolio;

  /// No description provided for @homeNeedAttention.
  ///
  /// In es, this message translates to:
  /// **'Necesitan atención'**
  String get homeNeedAttention;

  /// No description provided for @homeAiHint.
  ///
  /// In es, this message translates to:
  /// **'Pregúntale sobre tus clientes'**
  String get homeAiHint;

  /// No description provided for @homeUrgentCount.
  ///
  /// In es, this message translates to:
  /// **'{count} urgente(s)'**
  String homeUrgentCount(int count);

  /// No description provided for @homeUrgentToday.
  ///
  /// In es, this message translates to:
  /// **'{count} urgente(s) · hoy'**
  String homeUrgentToday(int count);

  /// No description provided for @homeAttentionDesc.
  ///
  /// In es, this message translates to:
  /// **'{count} póliza(s) necesitan tu atención'**
  String homeAttentionDesc(int count);

  /// No description provided for @homePolicies.
  ///
  /// In es, this message translates to:
  /// **'Pólizas'**
  String get homePolicies;

  /// No description provided for @homeToRenew.
  ///
  /// In es, this message translates to:
  /// **'Por renovar'**
  String get homeToRenew;

  /// No description provided for @homeClients.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get homeClients;

  /// No description provided for @homePendientes.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get homePendientes;

  /// No description provided for @homeSeguimientos.
  ///
  /// In es, this message translates to:
  /// **'Seguimientos'**
  String get homeSeguimientos;

  /// No description provided for @homeClientesRecientes.
  ///
  /// In es, this message translates to:
  /// **'Clientes recientes'**
  String get homeClientesRecientes;

  /// No description provided for @homeViewAgenda.
  ///
  /// In es, this message translates to:
  /// **'Ver agenda'**
  String get homeViewAgenda;

  /// No description provided for @homeViewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get homeViewAll;

  /// No description provided for @reminderTypePayment.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get reminderTypePayment;

  /// No description provided for @reminderTypeRenewal.
  ///
  /// In es, this message translates to:
  /// **'Renovación'**
  String get reminderTypeRenewal;

  /// No description provided for @reminderTypeCall.
  ///
  /// In es, this message translates to:
  /// **'Llamada'**
  String get reminderTypeCall;

  /// No description provided for @reminderTypeOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get reminderTypeOther;

  /// No description provided for @clientsTitle.
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get clientsTitle;

  /// No description provided for @clientsTotal.
  ///
  /// In es, this message translates to:
  /// **'{count} en total'**
  String clientsTotal(int count);

  /// No description provided for @clientsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar cliente…'**
  String get clientsSearchHint;

  /// No description provided for @clientsStatusProspect.
  ///
  /// In es, this message translates to:
  /// **'Prospecto'**
  String get clientsStatusProspect;

  /// No description provided for @clientsStatusToRenew.
  ///
  /// In es, this message translates to:
  /// **'Por renovar'**
  String get clientsStatusToRenew;

  /// No description provided for @clientsStatusPaymentDue.
  ///
  /// In es, this message translates to:
  /// **'Pago próximo'**
  String get clientsStatusPaymentDue;

  /// No description provided for @clientsStatusUpToDate.
  ///
  /// In es, this message translates to:
  /// **'Al día'**
  String get clientsStatusUpToDate;

  /// No description provided for @clientsActionCall.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get clientsActionCall;

  /// No description provided for @clientsActionMessage.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get clientsActionMessage;

  /// No description provided for @clientsActionRemind.
  ///
  /// In es, this message translates to:
  /// **'Recordar'**
  String get clientsActionRemind;

  /// No description provided for @clientsActionAsk.
  ///
  /// In es, this message translates to:
  /// **'Preguntar'**
  String get clientsActionAsk;

  /// No description provided for @clientsPoliciesTab.
  ///
  /// In es, this message translates to:
  /// **'Pólizas · {count}'**
  String clientsPoliciesTab(int count);

  /// No description provided for @clientsNotesTab.
  ///
  /// In es, this message translates to:
  /// **'Notas · {count}'**
  String clientsNotesTab(int count);

  /// No description provided for @clientsPolicyActive.
  ///
  /// In es, this message translates to:
  /// **'Vigente'**
  String get clientsPolicyActive;

  /// No description provided for @clientsPolicySumInsured.
  ///
  /// In es, this message translates to:
  /// **'Suma asegurada'**
  String get clientsPolicySumInsured;

  /// No description provided for @clientsPolicyPremium.
  ///
  /// In es, this message translates to:
  /// **'Prima'**
  String get clientsPolicyPremium;

  /// No description provided for @clientsPolicyNextPayment.
  ///
  /// In es, this message translates to:
  /// **'Próximo pago'**
  String get clientsPolicyNextPayment;

  /// No description provided for @clientsPolicyDeductible.
  ///
  /// In es, this message translates to:
  /// **'Deducible'**
  String get clientsPolicyDeductible;

  /// No description provided for @clientsAskAbout.
  ///
  /// In es, this message translates to:
  /// **'Preguntar sobre {name}'**
  String clientsAskAbout(String name);

  /// No description provided for @remindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get remindersTitle;

  /// No description provided for @remindersPendingCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pendientes'**
  String remindersPendingCount(int count);

  /// No description provided for @remindersFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get remindersFilterAll;

  /// No description provided for @remindersFilterPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get remindersFilterPayments;

  /// No description provided for @remindersFilterRenewals.
  ///
  /// In es, this message translates to:
  /// **'Renovaciones'**
  String get remindersFilterRenewals;

  /// No description provided for @remindersFilterCalls.
  ///
  /// In es, this message translates to:
  /// **'Llamadas'**
  String get remindersFilterCalls;

  /// No description provided for @remindersNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo recordatorio'**
  String get remindersNewTitle;

  /// No description provided for @remindersCreated.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio creado'**
  String get remindersCreated;

  /// No description provided for @remindersVoiceHint.
  ///
  /// In es, this message translates to:
  /// **'DÍSELO CON TUS PALABRAS'**
  String get remindersVoiceHint;

  /// No description provided for @remindersVoicePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'recuérdame llamar a José mañana a las 3'**
  String get remindersVoicePlaceholder;

  /// No description provided for @remindersFieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get remindersFieldTitle;

  /// No description provided for @remindersFieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get remindersFieldType;

  /// No description provided for @remindersFieldClient.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get remindersFieldClient;

  /// No description provided for @remindersFieldDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get remindersFieldDate;

  /// No description provided for @remindersFieldTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get remindersFieldTime;

  /// No description provided for @remindersRepeatYearly.
  ///
  /// In es, this message translates to:
  /// **'Repetir cada año'**
  String get remindersRepeatYearly;

  /// No description provided for @remindersCreateBtn.
  ///
  /// In es, this message translates to:
  /// **'Crear recordatorio'**
  String get remindersCreateBtn;

  /// No description provided for @voiceListening.
  ///
  /// In es, this message translates to:
  /// **'Escuchando…'**
  String get voiceListening;

  /// No description provided for @voiceTapToClose.
  ///
  /// In es, this message translates to:
  /// **'Toca para cerrar'**
  String get voiceTapToClose;

  /// No description provided for @voiceInputHint.
  ///
  /// In es, this message translates to:
  /// **'Pregunta…'**
  String get voiceInputHint;

  /// No description provided for @voiceSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get voiceSend;

  /// No description provided for @chatTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get chatTitle;

  /// No description provided for @chatSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Conectado a tu base'**
  String get chatSubtitle;

  /// No description provided for @chatNewConversation.
  ///
  /// In es, this message translates to:
  /// **'Nueva conversación'**
  String get chatNewConversation;

  /// No description provided for @chatInputHint.
  ///
  /// In es, this message translates to:
  /// **'Pregúntale a tu asistente…'**
  String get chatInputHint;

  /// No description provided for @feedTitle.
  ///
  /// In es, this message translates to:
  /// **'Base de conocimiento'**
  String get feedTitle;

  /// No description provided for @feedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Alimentar la app'**
  String get feedSubtitle;

  /// No description provided for @feedQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres agregar?'**
  String get feedQuestion;

  /// No description provided for @feedTypePolicyPdf.
  ///
  /// In es, this message translates to:
  /// **'Póliza PDF'**
  String get feedTypePolicyPdf;

  /// No description provided for @feedTypePolicyPdfDesc.
  ///
  /// In es, this message translates to:
  /// **'Sube la póliza y la leo completa'**
  String get feedTypePolicyPdfDesc;

  /// No description provided for @feedTypePolicyPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto de póliza'**
  String get feedTypePolicyPhoto;

  /// No description provided for @feedTypePolicyPhotoDesc.
  ///
  /// In es, this message translates to:
  /// **'Fotografía con tu cámara'**
  String get feedTypePolicyPhotoDesc;

  /// No description provided for @feedTypeAudio.
  ///
  /// In es, this message translates to:
  /// **'Audio / nota voz'**
  String get feedTypeAudio;

  /// No description provided for @feedTypeAudioDesc.
  ///
  /// In es, this message translates to:
  /// **'Transcribe y extrae datos'**
  String get feedTypeAudioDesc;

  /// No description provided for @feedTypeText.
  ///
  /// In es, this message translates to:
  /// **'Texto / notas'**
  String get feedTypeText;

  /// No description provided for @feedTypeTextDesc.
  ///
  /// In es, this message translates to:
  /// **'Pega chats o notas escritas'**
  String get feedTypeTextDesc;

  /// No description provided for @feedTypeWhatsapp.
  ///
  /// In es, this message translates to:
  /// **'Importar chat de WhatsApp'**
  String get feedTypeWhatsapp;

  /// No description provided for @feedTypeWhatsappDesc.
  ///
  /// In es, this message translates to:
  /// **'Exporta y sube la conversación'**
  String get feedTypeWhatsappDesc;

  /// No description provided for @feedRecentlyUploaded.
  ///
  /// In es, this message translates to:
  /// **'Subido recientemente'**
  String get feedRecentlyUploaded;

  /// No description provided for @feedUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo archivo…'**
  String get feedUploading;

  /// No description provided for @feedProcessing.
  ///
  /// In es, this message translates to:
  /// **'Procesando con IA…'**
  String get feedProcessing;

  /// No description provided for @feedUploadingDesc.
  ///
  /// In es, this message translates to:
  /// **'Enviando el PDF a Supabase Storage'**
  String get feedUploadingDesc;

  /// No description provided for @feedProcessingDesc.
  ///
  /// In es, this message translates to:
  /// **'La IA está extrayendo los datos de la póliza'**
  String get feedProcessingDesc;

  /// No description provided for @feedSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Póliza creada'**
  String get feedSuccessTitle;

  /// No description provided for @feedSuccessFieldsSaved.
  ///
  /// In es, this message translates to:
  /// **'{count} datos guardados'**
  String feedSuccessFieldsSaved(int count);

  /// No description provided for @feedSuccessNewOne.
  ///
  /// In es, this message translates to:
  /// **'1 recordatorio nuevo'**
  String get feedSuccessNewOne;

  /// No description provided for @feedSuccessNewMany.
  ///
  /// In es, this message translates to:
  /// **'{count} recordatorios nuevos'**
  String feedSuccessNewMany(int count);

  /// No description provided for @feedSuccessExistingOne.
  ///
  /// In es, this message translates to:
  /// **'1 ya existía'**
  String get feedSuccessExistingOne;

  /// No description provided for @feedSuccessExistingMany.
  ///
  /// In es, this message translates to:
  /// **'{count} ya existían'**
  String feedSuccessExistingMany(int count);

  /// No description provided for @feedSuccessRemindersSection.
  ///
  /// In es, this message translates to:
  /// **'RECORDATORIOS'**
  String get feedSuccessRemindersSection;

  /// No description provided for @feedSuccessReminderNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get feedSuccessReminderNew;

  /// No description provided for @feedSuccessReminderExisting.
  ///
  /// In es, this message translates to:
  /// **'Ya existía'**
  String get feedSuccessReminderExisting;

  /// No description provided for @feedSuccessDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get feedSuccessDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
