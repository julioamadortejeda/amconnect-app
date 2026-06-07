import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/mock/mock_data.dart';

class RemindersNotifier extends Notifier<List<MockReminder>> {
  @override
  List<MockReminder> build() => mockReminders
      .map((r) => MockReminder(
            id: r.id, clienteId: r.clienteId, tipo: r.tipo, titulo: r.titulo,
            sub: r.sub, fecha: r.fecha, hora: r.hora, urgente: r.urgente, hecho: r.hecho,
          ))
      .toList();

  void toggle(String id) {
    state = [
      for (final r in state)
        if (r.id == id)
          MockReminder(
            id: r.id, clienteId: r.clienteId, tipo: r.tipo, titulo: r.titulo,
            sub: r.sub, fecha: r.fecha, hora: r.hora, urgente: r.urgente, hecho: !r.hecho,
          )
        else
          r,
    ];
  }
}

final remindersProvider =
    NotifierProvider<RemindersNotifier, List<MockReminder>>(RemindersNotifier.new);
