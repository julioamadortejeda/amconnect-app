// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonTerms =>
      'By continuing, you accept the Terms and Privacy Policy.';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAccount => 'Account';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonLoading => 'Loading...';

  @override
  String homeViewAllCount(int count) {
    return 'View all ($count)';
  }

  @override
  String get loginWelcomeTitle => 'Welcome to\nAMConnect';

  @override
  String get loginWelcomeSubtitle =>
      'Your intelligent assistant. Manage your clients, policies, and reminders — and ask it anything.';

  @override
  String get loginContinueApple => 'Continue with Apple';

  @override
  String get loginContinueGoogle => 'Continue with Google';

  @override
  String get loginEnterEmail => 'Sign in with email';

  @override
  String get loginGuest => 'Explore as guest';

  @override
  String get loginErrGoogle => 'Couldn\'t sign in with Google.';

  @override
  String get loginErrApple => 'Couldn\'t sign in with Apple.';

  @override
  String get emailLoginTitle => 'Sign in';

  @override
  String get emailLoginSubtitle => 'Enter your email and password';

  @override
  String get emailLoginForgot => 'Forgot your password?';

  @override
  String get emailLoginBtn => 'Sign in';

  @override
  String get emailLoginNoAccount => 'Don\'t have an account? ';

  @override
  String get emailLoginCreateAccount => 'Create account';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Sign up to start using AMConnect';

  @override
  String get registerBtn => 'Create account';

  @override
  String get registerHasAccount => 'Already have an account? ';

  @override
  String get registerSignIn => 'Sign in';

  @override
  String get fieldEmail => 'Email address';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldConfirm => 'Confirm password';

  @override
  String get errInvalidEmail => 'Enter a valid email address';

  @override
  String get errEmptyCredentials => 'Please fill in all fields';

  @override
  String get errWrongCredentials => 'Email or password is incorrect';

  @override
  String get errFillAll => 'Please complete all fields';

  @override
  String get errPasswordMismatch => 'Passwords don\'t match';

  @override
  String get errCreateAccount => 'Error creating account. Please try again.';

  @override
  String get shellHome => 'Home';

  @override
  String get shellAgenda => 'Agenda';

  @override
  String get shellClients => 'Clients';

  @override
  String get shellData => 'Data';

  @override
  String get homeTitle => 'AMConnect';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeGreetingDefault => 'Hello! Good day';

  @override
  String get homeImmediateAttention => 'Immediate attention';

  @override
  String get homePortfolio => 'Your portfolio';

  @override
  String get homeNeedAttention => 'Need attention';

  @override
  String get homeAiHint => 'Ask about your clients';

  @override
  String homeUrgentCount(int count) {
    return '$count urgent';
  }

  @override
  String homeUrgentToday(int count) {
    return '$count urgent · today';
  }

  @override
  String homeAttentionDesc(int count) {
    return '$count policy(ies) need your attention';
  }

  @override
  String get homePolicies => 'Policies';

  @override
  String get homeToRenew => 'To renew';

  @override
  String get homeClients => 'Clients';

  @override
  String get homePendientes => 'Pending';

  @override
  String get homeSeguimientos => 'Follow-ups';

  @override
  String get homeClientesRecientes => 'Recent clients';

  @override
  String get homeViewAgenda => 'View schedule';

  @override
  String get homeViewAll => 'View all';

  @override
  String get reminderTypePayment => 'Payment';

  @override
  String get reminderTypeRenewal => 'Renewal';

  @override
  String get reminderTypeCall => 'Call';

  @override
  String get reminderTypeOther => 'Other';

  @override
  String get clientsTitle => 'Clients';

  @override
  String clientsTotal(int count) {
    return '$count total';
  }

  @override
  String get clientsSearchHint => 'Search client…';

  @override
  String get clientsStatusProspect => 'Prospect';

  @override
  String get clientsStatusToRenew => 'To renew';

  @override
  String get clientsStatusPaymentDue => 'Payment due';

  @override
  String get clientsStatusUpToDate => 'Up to date';

  @override
  String get clientsActionCall => 'Call';

  @override
  String get clientsActionMessage => 'Message';

  @override
  String get clientsActionRemind => 'Remind';

  @override
  String get clientsActionAsk => 'Ask';

  @override
  String clientsPoliciesTab(int count) {
    return 'Policies · $count';
  }

  @override
  String clientsNotesTab(int count) {
    return 'Notes · $count';
  }

  @override
  String get clientsPolicyActive => 'Active';

  @override
  String get clientsPolicySumInsured => 'Sum insured';

  @override
  String get clientsPolicyPremium => 'Premium';

  @override
  String get clientsPolicyNextPayment => 'Next payment';

  @override
  String get clientsPolicyDeductible => 'Deductible';

  @override
  String clientsAskAbout(String name) {
    return 'Ask about $name';
  }

  @override
  String get remindersTitle => 'Agenda';

  @override
  String remindersPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get remindersFilterAll => 'All';

  @override
  String get remindersFilterPayments => 'Payments';

  @override
  String get remindersFilterRenewals => 'Renewals';

  @override
  String get remindersFilterCalls => 'Calls';

  @override
  String get remindersNewTitle => 'New reminder';

  @override
  String get remindersCreated => 'Reminder created';

  @override
  String get remindersVoiceHint => 'SAY IT IN YOUR OWN WORDS';

  @override
  String get remindersVoicePlaceholder =>
      'remind me to call José tomorrow at 3';

  @override
  String get remindersFieldTitle => 'Title';

  @override
  String get remindersFieldType => 'Type';

  @override
  String get remindersFieldClient => 'Client';

  @override
  String get remindersFieldDate => 'Date';

  @override
  String get remindersFieldTime => 'Time';

  @override
  String get remindersRepeatYearly => 'Repeat yearly';

  @override
  String get remindersCreateBtn => 'Create reminder';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceTapToClose => 'Tap to close';

  @override
  String get voiceInputHint => 'Ask anything…';

  @override
  String get voiceSend => 'Send';

  @override
  String get chatTitle => 'Assistant';

  @override
  String get chatSubtitle => 'Connected to your base';

  @override
  String get chatNewConversation => 'New conversation';

  @override
  String get chatInputHint => 'Ask your assistant…';

  @override
  String get feedTitle => 'Knowledge base';

  @override
  String get feedSubtitle => 'Feed the app';

  @override
  String get feedQuestion => 'What do you want to add?';

  @override
  String get feedTypePolicyPdf => 'Policy PDF';

  @override
  String get feedTypePolicyPdfDesc => 'Upload the policy and I\'ll read it';

  @override
  String get feedTypePolicyPhoto => 'Policy photo';

  @override
  String get feedTypePolicyPhotoDesc => 'Take a photo with your camera';

  @override
  String get feedTypeAudio => 'Audio / voice note';

  @override
  String get feedTypeAudioDesc => 'Transcribes and extracts data';

  @override
  String get feedTypeText => 'Text / notes';

  @override
  String get feedTypeTextDesc => 'Paste chats or written notes';

  @override
  String get feedTypeWhatsapp => 'Import WhatsApp chat';

  @override
  String get feedTypeWhatsappDesc => 'Export and upload the conversation';

  @override
  String get feedRecentlyUploaded => 'Recently uploaded';

  @override
  String get feedUploading => 'Uploading file…';

  @override
  String get feedProcessing => 'Processing with AI…';

  @override
  String get feedUploadingDesc => 'Sending the PDF to Supabase Storage';

  @override
  String get feedProcessingDesc => 'AI is extracting policy data';

  @override
  String get feedSuccessTitle => 'Policy created';

  @override
  String feedSuccessFieldsSaved(int count) {
    return '$count fields saved';
  }

  @override
  String get feedSuccessNewOne => '1 new reminder';

  @override
  String feedSuccessNewMany(int count) {
    return '$count new reminders';
  }

  @override
  String get feedSuccessExistingOne => '1 already existed';

  @override
  String feedSuccessExistingMany(int count) {
    return '$count already existed';
  }

  @override
  String get feedSuccessRemindersSection => 'REMINDERS';

  @override
  String get feedSuccessReminderNew => 'New';

  @override
  String get feedSuccessReminderExisting => 'Already existed';

  @override
  String get feedSuccessDone => 'Done';
}
