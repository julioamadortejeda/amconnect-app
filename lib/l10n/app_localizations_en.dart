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
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAccount => 'Account';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get homeEmptyPendientes => 'No pending reminders';

  @override
  String get homeEmptySeguimientos => 'No active follow-ups';

  @override
  String get homeEmptyClientes => 'No clients registered yet';

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
  String get currencyMXN => 'Mexican Peso';

  @override
  String get currencyUSD => 'US Dollar';

  @override
  String get paymentMethodDirectDebit => 'Direct Debit';

  @override
  String get paymentMethodBankTransfer => 'Bank Transfer';

  @override
  String get paymentMethodCheck => 'Check';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCreditCard => 'Credit Card';

  @override
  String get paymentFrequencyMonthly => 'Monthly';

  @override
  String get paymentFrequencyQuarterly => 'Quarterly';

  @override
  String get paymentFrequencySemiannual => 'Semiannual';

  @override
  String get paymentFrequencyAnnual => 'Annual';

  @override
  String get participantRoleHolder => 'Holder';

  @override
  String get participantRoleInsured => 'Insured';

  @override
  String get participantRolePolicyholder => 'Policyholder';

  @override
  String get participantRoleDependent => 'Dependent';

  @override
  String get policyStatusActive => 'Active';

  @override
  String get policyStatusCancelled => 'Cancelled';

  @override
  String get policyStatusExpired => 'Expired';

  @override
  String get policyStatusPending => 'Pending';

  @override
  String get policyStatusSuspended => 'Suspended';

  @override
  String get reminderStatusCreated => 'Created';

  @override
  String get reminderStatusInProgress => 'In Progress';

  @override
  String get reminderStatusDone => 'Done';

  @override
  String get reminderStatusCancelled => 'Cancelled';

  @override
  String get reminderStatusPaused => 'Paused';

  @override
  String get reminderTypePayment => 'Payment';

  @override
  String get reminderTypeRenewal => 'Renewal';

  @override
  String get reminderTypeCancellation => 'Cancellation';

  @override
  String get reminderTypeFollowUp => 'Follow-up';

  @override
  String get reminderTypeCall => 'Call';

  @override
  String get reminderTypeAppointment => 'Appointment';

  @override
  String get reminderTypeAnniversary => 'Policy Anniversary';

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
  String get clientsEmpty => 'No registered clients';

  @override
  String get clientsError => 'Error loading clients';

  @override
  String get clientsContactSection => 'Contact';

  @override
  String get clientsNoPolicies => 'No registered policies';

  @override
  String get clientsNoNotes => 'No notes';

  @override
  String get clientsStatusProspect => 'Prospect';

  @override
  String get clientsStatusToRenew => 'To renew';

  @override
  String get clientsStatusPaymentDue => 'Payment due';

  @override
  String get clientsStatusUpToDate => 'Up to date';

  @override
  String clientsAge(int count) {
    return '$count years old';
  }

  @override
  String clientsMemberSince(int year) {
    return 'Client since $year';
  }

  @override
  String get clientsNewClient => 'Client';

  @override
  String get clientsNoteTypePdf => 'PDF document';

  @override
  String get clientsNoteTypeAudio => 'Voice note';

  @override
  String get clientsNoteTypeImage => 'Image';

  @override
  String get clientsNoteTypeText => 'Chat message';

  @override
  String get clientsNoteOpenFile => 'Open file';

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
  String get clientsPolicyEndDate => 'End date';

  @override
  String get clientsPolicyFiles => 'Files';

  @override
  String get clientsPolicyFileObsolete => 'Obsolete';

  @override
  String clientsPolicyOldVersions(int count) {
    return 'Previous versions ($count)';
  }

  @override
  String get clientsPolicyDeleteNoteTitle => 'Delete file';

  @override
  String get clientsPolicyDeleteNoteMsg =>
      'This version is no longer active. Do you want to delete it?';

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
  String get remindersFilterDeleted => 'Deleted';

  @override
  String get remindersDeletedWarning => 'Deleted reminders cannot be restored.';

  @override
  String get remindersEmpty => 'No reminders to show';

  @override
  String get remindersError => 'Error loading reminders';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarSun => 'S';

  @override
  String get calendarMon => 'M';

  @override
  String get calendarTue => 'T';

  @override
  String get calendarWed => 'W';

  @override
  String get calendarThu => 'T';

  @override
  String get calendarFri => 'F';

  @override
  String get calendarSat => 'S';

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
  String get voiceTapToSend => 'Tap to send';

  @override
  String get voiceTapToStart => 'Tap to speak';

  @override
  String get voiceNotAvailable => 'Voice not available';

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
  String get feedTypeKnowledgeImage => 'Image / screenshot';

  @override
  String get feedTypeKnowledgeImageDesc => 'Photo, screenshot or image file';

  @override
  String get feedTypeDocument => 'Knowledge PDF';

  @override
  String get feedTypeDocumentDesc => 'Document, manual, contract…';

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
  String get feedStepGettingUrl => 'Getting upload link…';

  @override
  String get feedStepUploading => 'Uploading file to server…';

  @override
  String get feedStepProcessing => 'Processing file with AI…';

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

  @override
  String get feedKnowledgeSuccessTitle => 'Saved!';

  @override
  String get feedKnowledgeDone => 'Close';

  @override
  String get feedTextInputTitle => 'Add note or text';

  @override
  String get feedWhatsappInputTitle => 'Import conversation';

  @override
  String get feedTextInputHint =>
      'Paste your text, notes or conversation here…';

  @override
  String get feedTextInputSubmit => 'Process';

  @override
  String get remindersActionDone => 'Mark done';

  @override
  String get remindersActionInProgress => 'In progress';

  @override
  String get remindersActionReschedule => 'Reschedule';

  @override
  String get remindersActionCancel => 'Cancel';

  @override
  String get remindersActionCancelTitle => 'Cancel reminder';

  @override
  String get remindersActionCancelHint => 'Why is it being cancelled?';

  @override
  String get remindersActionCancelBtn => 'Confirm cancellation';

  @override
  String get remindersActionCommentRequired =>
      'A comment is required to cancel';

  @override
  String get remindersConfirmDoneTitle => 'Complete Reminder';

  @override
  String get remindersConfirmDoneMessage =>
      'Are you sure you want to mark this reminder as completed?';

  @override
  String get remindersConfirmDoneBtn => 'Complete';

  @override
  String get remindersConfirmCancelBtn => 'Cancel';

  @override
  String get remindersConfirmInProgressTitle => 'Set In Progress';

  @override
  String get remindersConfirmInProgressMessage =>
      'Do you want to mark this reminder as \"In Progress\"?';

  @override
  String get remindersConfirmInProgressBtn => 'OK';

  @override
  String get remindersRescheduleTitle => 'Reschedule Reminder';

  @override
  String get remindersRescheduleMessage =>
      'Select the new date and time for this task.';

  @override
  String get remindersRescheduleSave => 'Save';

  @override
  String get remindersFieldDateUpper => 'DATE';

  @override
  String get remindersFieldTimeUpper => 'TIME';

  @override
  String get remindersCancelTitle => 'Cancel Reminder';

  @override
  String get remindersCancelHint => 'Type the reason for cancellation...';

  @override
  String get remindersCancelConfirmBtn => 'Confirm';

  @override
  String get remindersDetailTitle => 'Reminder';

  @override
  String get remindersDetailEdit => 'Edit';

  @override
  String get remindersDetailSave => 'Save';

  @override
  String get remindersDetailNotes => 'Notes';

  @override
  String get remindersDetailNoNotes => 'No notes';

  @override
  String get remindersDetailNoClient => 'No client assigned';

  @override
  String get remindersDetailSaved => 'Changes saved';

  @override
  String get remindersDetailStatus => 'Status';

  @override
  String get remindersDetailDatetime => 'Date & time';

  @override
  String get remindersDetailActions => 'Actions';

  @override
  String get reminderPriorityUrgent => 'Urgent';

  @override
  String get reminderPriorityWarning => 'Soon';

  @override
  String get reminderPriorityNormal => 'Normal';

  @override
  String get remindersDetailDueDate => 'Due date';

  @override
  String get remindersDetailCreatedAt => 'Created on';

  @override
  String get remindersDetailPolicy => 'Policy';

  @override
  String get remindersDetailSelectType => 'Reminder type';

  @override
  String get remindersDetailSelectStatus => 'Reminder status';

  @override
  String get remindersDetailComments => 'Comments';

  @override
  String get remindersDetailNoComments => 'No comments';

  @override
  String get remindersDetailNoDescription => 'No description';

  @override
  String get remindersDetailRelations => 'Relations';

  @override
  String get remindersDetailTomorrow => 'Tomorrow';

  @override
  String remindersDetailDaysLeft(int count) {
    return '${count}d';
  }

  @override
  String remindersDetailDaysOverdue(int count) {
    return '${count}d overdue';
  }
}
