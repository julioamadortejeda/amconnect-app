import '../../../l10n/app_localizations.dart';

extension CatalogL10n on AppLocalizations {
  String currency(String code) => {
    'MXN': currencyMXN,
    'USD': currencyUSD,
  }[code] ?? code;

  String paymentMethod(String code) => {
    'DIRECT_DEBIT': paymentMethodDirectDebit,
    'BANK_TRANSFER': paymentMethodBankTransfer,
    'CHECK':         paymentMethodCheck,
    'CASH':          paymentMethodCash,
    'CREDIT_CARD':   paymentMethodCreditCard,
  }[code] ?? code;

  String paymentFrequency(String code) => {
    'MONTHLY':    paymentFrequencyMonthly,
    'QUARTERLY':  paymentFrequencyQuarterly,
    'SEMIANNUAL': paymentFrequencySemiannual,
    'ANNUAL':     paymentFrequencyAnnual,
  }[code] ?? code;

  String participantRole(String code) => {
    'HOLDER':       participantRoleHolder,
    'INSURED':      participantRoleInsured,
    'POLICYHOLDER': participantRolePolicyholder,
    'DEPENDENT':    participantRoleDependent,
  }[code] ?? code;

  String policyStatus(String code) => {
    'ACTIVE':    policyStatusActive,
    'CANCELLED': policyStatusCancelled,
    'EXPIRED':   policyStatusExpired,
    'PENDING':   policyStatusPending,
    'SUSPENDED': policyStatusSuspended,
  }[code] ?? code;

  String reminderType(String code) => {
    'PAYMENT':      reminderTypePayment,
    'RENEWAL':      reminderTypeRenewal,
    'CANCELLATION': reminderTypeCancellation,
    'FOLLOW_UP':    reminderTypeFollowUp,
    'CALL':         reminderTypeCall,
    'APPOINTMENT':  reminderTypeAppointment,
    'ANNIVERSARY':  reminderTypeAnniversary,
    'OTHER':        reminderTypeOther,
  }[code] ?? code;

  String reminderStatus(String code) => {
    'CREATED':     reminderStatusCreated,
    'PENDING':     reminderStatusPending,
    'IN_PROGRESS': reminderStatusInProgress,
    'DONE':        reminderStatusDone,
    'CANCELLED':   reminderStatusCancelled,
  }[code] ?? code;
}
