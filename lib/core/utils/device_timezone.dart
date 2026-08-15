import 'package:flutter_timezone/flutter_timezone.dart';

/// Zona horaria del dispositivo para los headers del API (`x-timezone` /
/// `x-timezone-offset`).
///
/// `DateTime.now().timeZoneName` NO devuelve un nombre IANA (iOS reporta
/// abreviaturas como "CST", que el backend interpretaría como otra zona), así
/// que el identificador IANA real se obtiene del SO vía flutter_timezone una
/// sola vez en [init]. Si el plugin falla, [name] cae a la abreviatura y el
/// backend resuelve la hora con [offset] como respaldo.
class DeviceTimezone {
  DeviceTimezone._();

  static String? _iana;

  /// Llamar una vez en main() antes de runApp.
  static Future<void> init() async {
    try {
      _iana = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      // Sin IANA disponible: el backend usa x-timezone-offset como respaldo.
    }
  }

  /// Identificador IANA ("America/Mexico_City") o, si init falló, el nombre
  /// que reporte el SO ("CST").
  static String get name => _iana ?? DateTime.now().timeZoneName;

  /// Offset actual del dispositivo en formato "-06:00".
  static String get offset {
    final o = DateTime.now().timeZoneOffset;
    final sign = o.isNegative ? '-' : '+';
    final h = o.inHours.abs().toString().padLeft(2, '0');
    final m = (o.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }
}
