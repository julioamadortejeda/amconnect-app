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
const _monthsFull = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre'
];
const _weekdaysFull = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo'
];

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// "Junio 2026" — encabezado de mes del calendario
String fmtMonthYear(DateTime dt) =>
    '${_cap(_monthsFull[dt.month - 1])} ${dt.year}';

// "Junio" — nombre completo del mes, capitalizado
String fmtMonthFull(DateTime dt) => _cap(_monthsFull[dt.month - 1]);

// "Lunes" — nombre completo del día de la semana, capitalizado
String fmtWeekdayFull(DateTime dt) => _cap(_weekdaysFull[dt.weekday - 1]);

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

/// Un día recurrente de la regla de pago: "10 may". Sin año a propósito — la
/// regla se repite cada año, solo la ocurrencia concreta lleva año.
String fmtMonthDay(int month, int day) => '$day ${_months[month - 1]}';

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
  if (d == today.add(const Duration(days: 1))) {
    return l10n.remindersDetailTomorrow;
  }
  return fmtDate(dt, showYear: showYear);
}

// "Hoy, 17:02" / "Mañana" / "13 jun 2026, 09:00" — día inteligente + hora.
// Convierte a hora local del dispositivo; medianoche local = sin hora → solo día.
String fmtSmartDateTime(DateTime? dt, AppLocalizations l10n,
    {bool showYear = false}) {
  if (dt == null) return '—';
  final local = dt.toLocal();
  final day = fmtSmartDate(local, l10n, showYear: showYear);
  final time = fmtTime(local, fallback: '');
  return time.isEmpty ? day : '$day, $time';
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

// "mm:ss" — duración de una grabación en curso o terminada.
String fmtElapsed(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

// ─── Names and Strings ────────────────────────────────────────────────────────

/// Splits a full name into a first name and a last name.
(String, String?) splitFullName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  final firstName = parts.isNotEmpty ? parts.first : fullName;
  final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
  return (firstName, lastName);
}

/// Generates initials for a full name (up to 2 letters).
String getInitials(String fullName) {
  final clean = fullName.trim();
  if (clean.isEmpty) return '';
  final parts = clean.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final p1 = parts[0];
    final p2 = parts[1];
    return '${p1.isEmpty ? '' : p1[0]}${p2.isEmpty ? '' : p2[0]}'.toUpperCase();
  }
  final single = parts[0];
  return single.substring(0, single.length.clamp(0, 2)).toUpperCase();
}

// "Hoy" / "Ayer" / "lun" / "13 jun" — fecha relativa corta para listas del Feed
String fmtRelativeDay(DateTime? dt, AppLocalizations l10n) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(local.year, local.month, local.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return l10n.calendarToday;
  if (diff == 1) return l10n.commonYesterday;
  if (diff > 1 && diff < 7) return _weekdays[local.weekday - 1];
  return fmtDate(local, showYear: false);
}
