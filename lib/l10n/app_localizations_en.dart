// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AMConnect Advisor';

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
  String get commonYesterday => 'Yesterday';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonOpenSettings => 'Open Settings';

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
  String get forgotPasswordTitle => 'Recover your account';

  @override
  String get forgotPasswordSubtitleEmail =>
      'Enter your email and we\'ll send you a code to reset your password.';

  @override
  String get forgotPasswordSubtitleReset =>
      'Enter the code we sent you and your new password.';

  @override
  String forgotPasswordCodeSentTo(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get forgotPasswordSendCodeBtn => 'Send code';

  @override
  String get forgotPasswordResetBtn => 'Reset password';

  @override
  String get forgotPasswordBackToEmail => 'Use a different email';

  @override
  String get forgotPasswordSuccessTitle => 'Password updated';

  @override
  String get forgotPasswordSuccessMsg =>
      'You can now sign in with your new password.';

  @override
  String get forgotPasswordSuccessBtn => 'Sign in';

  @override
  String get errRequestCodeFailed =>
      'We couldn\'t send the code. Please try again.';

  @override
  String get errInvalidCode => 'The code is invalid or has expired.';

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
  String get fieldCode => 'Verification code';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldPhone => 'Phone';

  @override
  String get fieldOccupation => 'Occupation';

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldBirthdate => 'Birthdate';

  @override
  String get fieldRfc => 'RFC';

  @override
  String get fieldCurp => 'CURP';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get accountProfileTitle => 'Profile';

  @override
  String get accountPlanTitle => 'Your plan';

  @override
  String get accountEdit => 'Edit';

  @override
  String get accountSave => 'Save';

  @override
  String get accountSaved => 'Changes saved';

  @override
  String get accountErrSave => 'Couldn\'t save changes. Please try again.';

  @override
  String accountPlanPrice(String price) {
    return '$price MXN/month';
  }

  @override
  String get accountPlanStatusTrial => 'Trial';

  @override
  String get accountPlanStatusActive => 'Active';

  @override
  String get accountPlanStatusExpired => 'Expired';

  @override
  String get accountPlanStatusCancelled => 'Cancelled';

  @override
  String accountTrialDaysLeft(int count) {
    return '$count days left in trial';
  }

  @override
  String get accountUsageChatLabel => 'Chat messages';

  @override
  String get accountUsageIngestionsLabel => 'Documents processed';

  @override
  String accountUsageFormat(int used, int limit) {
    return '$used of $limit';
  }

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutMessage => 'You can sign back in anytime.';

  @override
  String get accountHelpTitle => 'Help';

  @override
  String get accountHelp => 'Help & support';

  @override
  String get accountNotificationsDisabled => 'Notifications disabled';

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
  String get errModelBusy =>
      'The AI assistant is currently busy. Please try again in a few seconds.';

  @override
  String get errSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errNotFound => 'Resource not found.';

  @override
  String get errUnknown => 'An unexpected error occurred. Please try again.';

  @override
  String get errNetwork =>
      'Connection error. Please check your internet and try again.';

  @override
  String get errQuotaExceeded =>
      'You\'ve reached your plan limit for this month. Upgrade your plan to continue.';

  @override
  String get errSubscriptionRequired =>
      'Your subscription has expired. Activate a plan to continue.';

  @override
  String get errValidationFailed =>
      'The submitted data is invalid. Please review it and try again.';

  @override
  String get errConflict => 'A record with that data already exists.';

  @override
  String get errAccessDenied =>
      'You don\'t have permission to perform this action.';

  @override
  String get errAiFailed =>
      'The assistant had a problem processing your request. Please try again.';

  @override
  String get errUploadFailed =>
      'The file could not be uploaded. Please try again.';

  @override
  String errRefCode(String ref) {
    return 'Reference code: $ref';
  }

  @override
  String get errFilePickerTimeout =>
      'File selection took too long. Please try again.';

  @override
  String get errFilePickerOpen => 'Could not open the file picker.';

  @override
  String get errFilePathUnavailable =>
      'Could not get the path of the selected file.';

  @override
  String get shellHome => 'Home';

  @override
  String get shellAgenda => 'Agenda';

  @override
  String get shellClients => 'Portfolio';

  @override
  String get shellData => 'Data';

  @override
  String get analyticsTitle => 'Portfolio Analytics';

  @override
  String get analyticsFunnelTitle => 'Sales Funnel';

  @override
  String get analyticsFunnelProspects => 'Prospects';

  @override
  String get analyticsFunnelClients => 'Clients with Policies';

  @override
  String get analyticsFunnelRate => 'Close Rate';

  @override
  String get analyticsPolicyStatus => 'Renewal Status';

  @override
  String get analyticsPolicyActive => 'Active';

  @override
  String get analyticsPolicyExpired => 'Expired / Overdue';

  @override
  String get analyticsPolicyPending => 'In Underwriting';

  @override
  String get analyticsBranchDist => 'Diversification by Line of Business';

  @override
  String get analyticsCarrierDist => 'Distribution by Carrier';

  @override
  String get homeNotificationsBannerTitle => 'Notifications disabled';

  @override
  String get homeNotificationsBannerSubtitle =>
      'Turn them on so you don\'t miss your reminders';

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
  String get clientsTabClients => 'Clients';

  @override
  String get clientsTabPolicies => 'Policies';

  @override
  String get clientsSearchPolicyHint => 'Search policy, carrier or product…';

  @override
  String get clientsEmptyPolicies => 'No policies in portfolio';

  @override
  String get clientsErrorPolicies => 'Error loading policies';

  @override
  String get clientsEmpty => 'No registered clients';

  @override
  String get clientsError => 'Error loading clients';

  @override
  String get clientsDeleteTitle => 'Delete client?';

  @override
  String get clientsDeleteMessage =>
      'This client will be deleted and will no longer appear in your portfolio. This action cannot be undone.';

  @override
  String get clientsErrDelete =>
      'Couldn\'t delete the client. Please try again.';

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
  String get clientsNewTitle => 'New client';

  @override
  String get clientsEditTitle => 'Edit client';

  @override
  String get clientsCreateBtn => 'Create client';

  @override
  String get clientsCreated => 'Client created';

  @override
  String get clientsUpdated => 'Client updated';

  @override
  String get clientsFieldNoBirthdate => 'No date set';

  @override
  String get clientsFieldInvalidPhone =>
      'Enter a valid phone number (10 to 15 digits)';

  @override
  String get clientsSectionPersonal => 'Personal info';

  @override
  String get clientsSectionFiscal => 'Fiscal';

  @override
  String get clientsFieldGeneralNotes => 'General notes';

  @override
  String get clientsAddNote => 'Add note';

  @override
  String get clientsAddNoteHint => 'Write a note about this client…';

  @override
  String get clientsNoteTypePdf => 'PDF document';

  @override
  String get clientsNoteTypeAudio => 'Voice note';

  @override
  String get clientsNoteTypeImage => 'Image';

  @override
  String get clientsNoteTypeText => 'Note';

  @override
  String get clientsNoteTypeWhatsapp => 'WhatsApp';

  @override
  String get clientsNoteOpenFile => 'Open file';

  @override
  String get clientsActionCall => 'Call';

  @override
  String get clientsActionMessage => 'Message';

  @override
  String get clientsActionRemind => 'Remind';

  @override
  String get clientsActionUpload => 'Upload';

  @override
  String get clientsActionAsk => 'Ask';

  @override
  String get clientsActionNoPhone => 'This client has no phone number on file';

  @override
  String get clientsActionLaunchError => 'Couldn\'t open the app';

  @override
  String get clientsActionInvalidPhone =>
      'This client\'s phone number isn\'t valid';

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
  String get remindersAskAbout => 'Ask about this';

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
  String get remindersFilterCompleted => 'Completed';

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
  String get remindersSectionInfo => 'Information';

  @override
  String get remindersSectionDetails => 'Details';

  @override
  String get remindersVoiceHint => 'SAY IT IN YOUR OWN WORDS';

  @override
  String get remindersVoicePlaceholder =>
      'remind me to call José tomorrow at 3';

  @override
  String get remindersFieldTitle => 'Title';

  @override
  String get remindersFieldDescription => 'Description';

  @override
  String get remindersFieldType => 'Type';

  @override
  String get remindersFieldClient => 'Client';

  @override
  String get remindersFieldDate => 'Date';

  @override
  String get remindersFieldTime => 'Time';

  @override
  String get remindersFieldDateTime => 'Date & time';

  @override
  String get remindersRepeatYearly => 'Repeat yearly';

  @override
  String get remindersCreateBtn => 'Create reminder';

  @override
  String get remindersSelectClientTitle => 'Select client';

  @override
  String get remindersNoClientOption => 'No client';

  @override
  String get remindersSelectPolicyTitle => 'Select policy';

  @override
  String get remindersNoPolicyOption => 'No policy';

  @override
  String get remindersSelectStatusTitle => 'Select status';

  @override
  String get remindersPolicyNeedsClient => 'Choose a client first';

  @override
  String get remindersPickDateTitle => 'Reminder date & time';

  @override
  String get remindersPickDateMessage => 'Choose when you want to be reminded.';

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
  String get voiceChatConnecting => 'Connecting…';

  @override
  String get voiceChatSessionReady => 'Setting up session…';

  @override
  String get voiceChatListening => 'Listening…';

  @override
  String get voiceChatModelSpeaking => 'Responding…';

  @override
  String get voiceChatEnd => 'End session';

  @override
  String get voiceChatClosed => 'Session ended';

  @override
  String get voiceChatError => 'Connection error';

  @override
  String get voiceChatPermissionDenied => 'Microphone permission denied';

  @override
  String get voiceOpenSettingsHint => 'Tap to open Settings';

  @override
  String get voiceChatSkillActive => 'Looking up data…';

  @override
  String get voiceChatThinking => 'Thinking…';

  @override
  String get voiceOutputTitle => 'Audio output';

  @override
  String get voiceOutputSpeaker => 'Phone speaker';

  @override
  String get voiceOutputBluetooth => 'Bluetooth device';

  @override
  String get voiceOutputWired => 'Wired headphones';

  @override
  String get voiceOutputOther => 'Other device';

  @override
  String get voiceOutputNone => 'No audio devices available';

  @override
  String get voiceSkillSearchingContacts => 'Looking up client…';

  @override
  String get voiceSkillReviewingContacts => 'Reviewing your clients…';

  @override
  String get voiceSkillSavingContact => 'Updating client…';

  @override
  String get voiceSkillSearchingNotes => 'Searching your notes…';

  @override
  String get voiceSkillSavingNote => 'Saving note…';

  @override
  String get voiceSkillSearchingPolicies => 'Looking up policy…';

  @override
  String get voiceSkillReviewingPolicies => 'Reviewing your policies…';

  @override
  String get voiceSkillSavingPolicy => 'Saving policy…';

  @override
  String get voiceSkillSearchingReminders => 'Looking up reminders…';

  @override
  String get voiceSkillSavingReminder => 'Updating reminder…';

  @override
  String get voiceSkillCatalog => 'Checking catalog…';

  @override
  String get voiceSkillSavingCatalog => 'Saving to catalog…';

  @override
  String get voiceSkillPendingTask => 'Noting a pending item…';

  @override
  String get voiceSkillKnowledge => 'Searching your knowledge base…';

  @override
  String get assistantVoiceActive => 'Voice active';

  @override
  String get chatTitle => 'Assistant';

  @override
  String get chatBackendFree => 'Free';

  @override
  String get chatBackendEnterprise => 'Enterprise';

  @override
  String get chatSubtitle => 'Connected to your base';

  @override
  String get chatNewConversation => 'New conversation';

  @override
  String get chatInputHint => 'Ask your assistant…';

  @override
  String get chatCardViewProfile => 'View Profile';

  @override
  String get chatCardViewPolicy => 'View Policy';

  @override
  String get chatCardGoToAgenda => 'Go to Agenda';

  @override
  String get chatCardContactInfoTitle => 'Contact';

  @override
  String get chatCardContactListTitle => 'Matching Contacts';

  @override
  String get chatCardReminderListTitle => 'Reminders & Tasks';

  @override
  String get chatCardPolicyInfoTitle => 'Policy Found';

  @override
  String get chatCardActionCall => 'Call';

  @override
  String get chatCardActionWhatsApp => 'WhatsApp';

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
  String get feedViewModeIngest => 'Ingest';

  @override
  String get feedViewModeKnowledge => 'Knowledge';

  @override
  String get feedStatsPDFs => 'PDFs';

  @override
  String get feedStatsImages => 'Images';

  @override
  String get feedStatsAudios => 'Audios';

  @override
  String get feedStatsNotes => 'Notes';

  @override
  String get feedStatsChats => 'Chats';

  @override
  String get feedSearchHint => 'Search knowledge base...';

  @override
  String get feedSearchNoResults => 'No notes or documents found.';

  @override
  String get feedStatsTitle => 'Knowledge Summary';

  @override
  String get feedAllNotesTitle => 'All Notes';

  @override
  String get feedSuccessTitle => 'Policy created';

  @override
  String get feedSuccessUpdateTitle => 'Policy updated';

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
  String get feedConfirmPolicyTitle => 'Confirm policy';

  @override
  String get feedPreviewTitle => 'Confirm file';

  @override
  String get feedPreviewConfirm => 'Confirm';

  @override
  String get feedIngestConfirmCta => 'Yes, save';

  @override
  String get feedIngestCorrectCta => 'Correct / Chat';

  @override
  String get feedIngestCancelCta => 'Cancel';

  @override
  String get feedIngestHolderLabel => 'Policyholder';

  @override
  String get feedIngestCarrierLabel => 'Carrier';

  @override
  String get feedIngestBranchProductLabel => 'Branch / Prod.';

  @override
  String get feedIngestPolicyNumberLabel => 'Policy No.';

  @override
  String get feedIngestPremiumLabel => 'Premium';

  @override
  String get feedIngestValidityLabel => 'Validity';

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

  @override
  String get policiesNewPolicyTitle => 'New Policy';

  @override
  String get policiesPolicyNumber => 'Policy number';

  @override
  String get policiesCarrier => 'Carrier';

  @override
  String get policiesBranch => 'Branch';

  @override
  String get policiesProduct => 'Product';

  @override
  String get policiesStatus => 'Status';

  @override
  String get policiesCurrency => 'Currency';

  @override
  String get policiesPaymentFrequency => 'Payment frequency';

  @override
  String get policiesPaymentMethod => 'Payment method';

  @override
  String get policiesSumInsured => 'Sum insured';

  @override
  String get policiesPremium => 'Premium';

  @override
  String get policiesDeductible => 'Deductible';

  @override
  String get policiesStartDate => 'Start date';

  @override
  String get policiesEndDate => 'End date';

  @override
  String get policiesRenewalDate => 'Renewal date';

  @override
  String get policiesNextPaymentDate => 'Next payment';

  @override
  String get policiesNotes => 'Notes';

  @override
  String get policiesSaveBtn => 'Save policy';

  @override
  String get policiesSelectClient => 'Select client';

  @override
  String get policiesCreateCarrier => 'Create new Carrier';

  @override
  String get policiesCreateBranch => 'Create new Branch';

  @override
  String get policiesCreateProduct => 'Create new Product';

  @override
  String get policiesCreatedSuccess => 'Policy created successfully';

  @override
  String get policiesEditPolicyTitle => 'Edit Policy';

  @override
  String get policiesSaveChangesBtn => 'Save changes';

  @override
  String get policiesUpdatedSuccess => 'Policy updated successfully';

  @override
  String get policiesDetailTitle => 'Policy detail';

  @override
  String get policiesDetailLoadError => 'Couldn\'t load the policy.';

  @override
  String get policiesDetailCoverage => 'Coverage and payment';

  @override
  String get policiesDetailDates => 'Dates';

  @override
  String get policiesNotesSection => 'Notes';

  @override
  String get policiesEmptyNotes => 'No notes yet for this policy.';

  @override
  String get policiesAddNoteHint => 'Write a note...';

  @override
  String get policiesDeleteNoteTitle => 'Delete note';

  @override
  String get policiesDeleteNoteMsg =>
      'Do you want to delete this note? This action cannot be undone.';

  @override
  String get policiesDeleteTitle => 'Delete policy?';

  @override
  String get policiesDeleteMessage =>
      'This policy will be deleted and will no longer appear in your portfolio. This action cannot be undone.';

  @override
  String get policiesErrDelete =>
      'Couldn\'t delete the policy. Please try again.';

  @override
  String get policiesAttachFile => 'Attach';

  @override
  String get catalogsTitle => 'Catalogs';

  @override
  String get catalogsTypeCarriers => 'Carriers';

  @override
  String get catalogsTypeBranches => 'Branches';

  @override
  String get catalogsTypeProducts => 'Products';

  @override
  String get catalogsSearchHint => 'Search...';

  @override
  String get catalogsEmpty => 'No results';

  @override
  String get catalogsError => 'Couldn\'t load catalogs';

  @override
  String get catalogsFieldName => 'Name';

  @override
  String get catalogsFieldShortName => 'Short name';

  @override
  String get catalogsFieldCode => 'Code';

  @override
  String get catalogsSelectCarrier => 'Select carrier';

  @override
  String get catalogsSelectBranch => 'Select branch';

  @override
  String get catalogsNewCarrierTitle => 'New carrier';

  @override
  String get catalogsEditCarrierTitle => 'Edit carrier';

  @override
  String get catalogsNewBranchTitle => 'New branch';

  @override
  String get catalogsEditBranchTitle => 'Edit branch';

  @override
  String get catalogsNewProductTitle => 'New product';

  @override
  String get catalogsEditProductTitle => 'Edit product';

  @override
  String get catalogsCreateBtn => 'Create';

  @override
  String get catalogsCarrierCreated => 'Carrier created';

  @override
  String get catalogsCarrierUpdated => 'Carrier updated';

  @override
  String get catalogsBranchCreated => 'Branch created';

  @override
  String get catalogsBranchUpdated => 'Branch updated';

  @override
  String get catalogsProductCreated => 'Product created';

  @override
  String get catalogsProductUpdated => 'Product updated';

  @override
  String get catalogsDeleteTitle => 'Delete item';

  @override
  String get catalogsDeleteMessage =>
      'Are you sure you want to delete it? This action cannot be undone.';
}
