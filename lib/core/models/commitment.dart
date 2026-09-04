/// Qué tan encima está el compromiso. Es lo ÚNICO que varía entre uno y otro
/// —no hay tipos, `label` es texto libre— así que es lo único que vale la pena
/// codificar visualmente.
enum CommitmentUrgency { overdue, soon, later }

/// Algo que quedó pendiente con un cliente, extraído por la IA de una nota.
///
/// No lo captura el asesor: sale de lo que dictó o escribió. Por eso [quote]
/// importa tanto como [label] — es la frase textual de su propia nota, y es lo
/// que hace que le crea a la app en vez de sospechar que se lo inventó.
class Commitment {
  const Commitment({
    required this.id,
    required this.label,
    required this.quote,
    this.contactId,
    this.clientName,
    this.dueFrom,
    this.dueTo,
    this.createdAt,
  });

  final String id;

  /// Qué quedó pendiente, en palabras de la IA ("buscar en noviembre").
  final String label;

  /// Fragmento literal de la nota del que salió.
  final String quote;

  /// Null cuando la nota se guardó como conocimiento general: el compromiso
  /// existe igual y el nombre vive dentro de [label] o [quote].
  final String? contactId;
  final String? clientName;

  /// Ventana en la que toca atenderlo. Nulas cuando la nota no dijo cuándo —
  /// ese compromiso envejece pero nunca sale en consultas por mes.
  final DateTime? dueFrom;
  final DateTime? dueTo;

  final DateTime? createdAt;

  bool get hasDate => dueTo != null;

  /// Hoy a medianoche. Todas las comparaciones van contra esto y no contra
  /// `DateTime.now()`: con la hora viva, "faltan 7 días" se cumplía o no según
  /// la hora a la que el asesor abriera la app, y el color de una fila cambiaba
  /// sola a media mañana.
  static DateTime _todayKey() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Días dentro de los cuales un compromiso ya cuenta como encima. Quince y no
  /// siete: el asesor planea por quincena, y con una ventana de una semana el
  /// indicador prácticamente nunca se encendía — de cuatro compromisos reales,
  /// ninguno caía dentro y la señal se leía como decorativa.
  static const _soonDays = 15;

  /// Lo que un compromiso SIN fecha puede envejecer antes de contar como
  /// urgente. Nadie puso plazo, así que no hay ventana que se pase, pero un mes
  /// esperando es justo lo que se le va al asesor.
  static const _staleDays = 30;

  /// Ya pasó su ventana y sigue abierto. Es lo que la app existe para evitar,
  /// así que se muestra primero y con más peso.
  bool get isOverdue {
    final end = dueTo;
    if (end == null) return false;
    return DateTime(end.year, end.month, end.day).isBefore(_todayKey());
  }

  CommitmentUrgency get urgency {
    final today = _todayKey();
    final end = dueTo;

    if (end == null) {
      final created = createdAt;
      if (created == null) return CommitmentUrgency.later;
      final born = DateTime(created.year, created.month, created.day);
      return today.difference(born).inDays >= _staleDays
          ? CommitmentUrgency.soon
          : CommitmentUrgency.later;
    }

    final endKey = DateTime(end.year, end.month, end.day);
    if (endKey.isBefore(today)) return CommitmentUrgency.overdue;
    return endKey.difference(today).inDays <= _soonDays
        ? CommitmentUrgency.soon
        : CommitmentUrgency.later;
  }

  static DateTime? _date(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  factory Commitment.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] as Map<String, dynamic>?;
    return Commitment(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      quote: json['quote'] as String? ?? '',
      contactId: json['contactId'] as String?,
      clientName: (json['clientName'] ?? contact?['fullName']) as String?,
      dueFrom: _date(json['dueFrom']),
      dueTo: _date(json['dueTo']),
      createdAt: _date(json['createdAt'])?.toLocal(),
    );
  }
}
