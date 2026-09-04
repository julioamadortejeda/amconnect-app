import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/commitment.dart';
import '../repositories/commitment_repository.dart';

/// Compromisos abiertos del asesor, ordenados por urgencia.
///
/// Los vencidos van primero: un compromiso cuya fecha ya pasó y sigue abierto es
/// exactamente lo que la app existe para evitar. Después los que tienen fecha,
/// por cercanía. Y al final los que no tienen — esos no son citas, son pendientes
/// que envejecen.
class CommitmentsNotifier extends AsyncNotifier<List<Commitment>> {
  late CommitmentRepository _repo;
  RealtimeChannel? _channel;
  Timer? _refetch;

  @override
  Future<List<Commitment>> build() async {
    _repo = ref.read(commitmentRepositoryProvider);
    final initial = await _repo.getOpen();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('commitments:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'client_commitments',
            filter: filter,
            callback: (_) => _scheduleReload(),
          )
          .subscribe((status, _) {
        debugPrint('[RT:commitments] $status');
      });

      ref.onDispose(() {
        _refetch?.cancel();
        _channel?.unsubscribe();
      });
    }

    return _sorted(initial);
  }

  /// Recarga la lista completa en vez de aplicar la fila del evento.
  ///
  /// A diferencia de recordatorios, aquí no se refresca por id: el evento de
  /// Postgres trae la fila cruda, sin el nombre del cliente —que viene de un
  /// join— así que habría que ir al servidor de todos modos. Y la lista es de
  /// unos cuantos pendientes, no de cientos: traerla entera cuesta lo mismo y
  /// deja el orden resuelto en un solo lugar.
  ///
  /// Con retardo porque un turno del asistente puede crear dos compromisos
  /// seguidos, y sin él la tarjeta parpadearía dos veces.
  void _scheduleReload() {
    _refetch?.cancel();
    _refetch = Timer(const Duration(milliseconds: 250), () async {
      try {
        state = AsyncData(_sorted(await _repo.getOpen()));
      } catch (_) {
        // Fire-and-forget a propósito (regla 6): esto es una recarga de fondo,
        // no una acción del asesor. Dejar el error en el estado cambiaría una
        // lista buena por una pantalla de error sin que él haya hecho nada; la
        // siguiente notificación —o abrir la app— la vuelve a intentar. Sin
        // detalle en el log: el error de red puede traer datos del asesor.
        debugPrint('[RT:commitments] recarga de fondo falló');
      }
    });
  }

  static List<Commitment> _sorted(List<Commitment> items) {
    final list = [...items];
    list.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      if (a.hasDate != b.hasDate) return a.hasDate ? -1 : 1;
      if (a.hasDate && b.hasDate) return a.dueTo!.compareTo(b.dueTo!);
      // Sin fecha, el más viejo primero: lleva más tiempo esperando.
      final ca = a.createdAt, cb = b.createdAt;
      if (ca != null && cb != null) return ca.compareTo(cb);
      return 0;
    });
    return list;
  }

  /// Quita el compromiso de la lista de inmediato y lo cierra en el servidor.
  /// Si falla, se restaura para que el asesor no crea que lo atendió.
  Future<void> close(String id, {String? resolutionNote, bool dismissed = false}) async {
    final previous = state.asData?.value;
    if (previous == null) return;

    state = AsyncData(previous.where((c) => c.id != id).toList());
    try {
      await _repo.close(id, resolutionNote: resolutionNote, dismissed: dismissed);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final commitmentsProvider =
    AsyncNotifierProvider<CommitmentsNotifier, List<Commitment>>(
        CommitmentsNotifier.new);

/// Los del cliente abierto, para mostrarlos en su ficha.
final contactCommitmentsProvider =
    Provider.autoDispose.family<List<Commitment>, String>((ref, contactId) {
  final all = ref.watch(commitmentsProvider).asData?.value ?? const [];
  return all.where((c) => c.contactId == contactId).toList();
});
