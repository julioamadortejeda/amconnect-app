import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic'
];
const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

// ─── Currency ─────────────────────────────────────────────────────────────────

String fmtCurrency(double? v) {
  if (v == null) return '—';
  return '\$${NumberFormat('#,##0', 'es_MX').format(v)}';
}

String fmtPremium(double? v, String freq) {
  if (v == null) return '—';
  final s = '\$${NumberFormat('#,##0', 'es_MX').format(v)}';
  return freq.isNotEmpty ? '$s · $freq' : s;
}

// ─── Dates ────────────────────────────────────────────────────────────────────

// "13 jun 2026" (showYear: true) or "13 jun" (showYear: false) — pure, no context
String fmtDate(DateTime? dt, {bool showYear = true}) {
  if (dt == null) return '—';
  final base = '${dt.day} ${_months[dt.month - 1]}';
  return showYear ? '$base ${dt.year}' : base;
}

// Wrapper para ISO strings
String fmtDateFromIso(String? iso, {bool showYear = true}) {
  if (iso == null) return '—';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '—';
  return fmtDate(dt, showYear: showYear);
}

// "Hoy" / "Mañana" / "13 jun [2026]" — requiere l10n para los labels localizados
String fmtSmartDate(DateTime? dt, AppLocalizations l10n,
    {bool showYear = false}) {
  if (dt == null) return '—';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) return l10n.calendarToday;
  if (d == today.add(const Duration(days: 1)))
    return l10n.remindersDetailTomorrow;
  return fmtDate(dt, showYear: showYear);
}

// "lun 13 jun 2026" — para timestamps de comentarios y pantallas de detalle
String fmtDateWithWeekday(DateTime? dt) {
  if (dt == null) return '—';
  return '${_weekdays[dt.weekday - 1]} ${dt.day} ${_months[dt.month - 1]} ${dt.year}';
}

// "HH:mm" — fallback '—' por defecto, pasar '' donde se necesite string vacío
String fmtTime(DateTime? dt, {String fallback = '—'}) {
  if (dt == null || (dt.hour == 0 && dt.minute == 0)) return fallback;
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
