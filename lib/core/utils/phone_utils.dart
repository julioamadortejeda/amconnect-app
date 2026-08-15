/// Teléfono opcional; si se captura, debe tener entre 10 y 15 dígitos
/// (acepta espacios/guiones/paréntesis/+ como separadores visuales).
bool isValidPhone(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return true;
  final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
  return digits.length >= 10 && digits.length <= 15;
}

/// Normaliza a formato internacional para `wa.me`. Los asesores capturan
/// el teléfono como número local de 10 dígitos (sin +52) — WhatsApp
/// necesita el código de país para resolver el chat. Si ya viene con
/// código de país (11-15 dígitos) se deja igual. `null` si no es un
/// teléfono con forma válida.
String? whatsAppDigits(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length == 10) return '52$digits';
  if (digits.length >= 11 && digits.length <= 15) return digits;
  return null;
}
