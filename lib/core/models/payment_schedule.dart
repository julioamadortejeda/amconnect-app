/// Calendario de pago de una póliza, **calculado por el backend**.
///
/// La app no deriva fechas: solo pinta lo que llega. Así la web y la app
/// muestran exactamente lo mismo sin reimplementar la regla en cada cliente.
class PaymentSchedule {
  const PaymentSchedule({
    required this.frequencyMonths,
    required this.ruleDays,
    required this.nextPaymentDate,
  });

  /// Meses entre pagos: 1 mensual, 3 trimestral, 6 semestral, 12 anual.
  final int frequencyMonths;

  /// La regla atemporal ("paga el 10 de may y el 10 de nov"). Viene vacía
  /// cuando la frecuencia no divide el año y no hay días fijos que mostrar.
  final List<PaymentRuleDay> ruleDays;

  /// La siguiente fecha real, en formato ISO `YYYY-MM-DD`.
  final String nextPaymentDate;

  DateTime? get nextPaymentAsDate => DateTime.tryParse(nextPaymentDate);

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) => PaymentSchedule(
        frequencyMonths: (json['frequencyMonths'] as num?)?.toInt() ?? 12,
        ruleDays: (json['ruleDays'] as List<dynamic>? ?? const [])
            .map((d) => PaymentRuleDay.fromJson(d as Map<String, dynamic>))
            .toList(),
        nextPaymentDate: json['nextPaymentDate'] as String? ?? '',
      );
}

/// Un día recurrente del año: `{month: 11, day: 10}` = 10 de noviembre.
class PaymentRuleDay {
  const PaymentRuleDay({required this.month, required this.day});

  final int month;
  final int day;

  factory PaymentRuleDay.fromJson(Map<String, dynamic> json) => PaymentRuleDay(
        month: (json['month'] as num).toInt(),
        day: (json['day'] as num).toInt(),
      );
}
