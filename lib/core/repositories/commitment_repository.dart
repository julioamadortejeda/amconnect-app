import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/commitment.dart';
import '../network/api_client.dart';

abstract class CommitmentRepository {
  /// Compromisos abiertos. Sin filtros trae todos los pendientes del asesor.
  Future<List<Commitment>> getOpen({DateTime? from, DateTime? to, String? contactId});

  /// Marca uno como atendido. [dismissed] cuando dejó de aplicar en vez de
  /// haberse cumplido.
  Future<void> close(String id, {String? resolutionNote, bool dismissed = false});
}

class SupabaseCommitmentRepository implements CommitmentRepository {
  SupabaseCommitmentRepository(this._client);
  final ApiClient _client;

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<Commitment>> getOpen({DateTime? from, DateTime? to, String? contactId}) async {
    final params = <String>[
      if (from != null) 'from=${_day(from)}',
      if (to != null) 'to=${_day(to)}',
      if (contactId != null) 'contactId=$contactId',
    ];
    final query = params.isEmpty ? '' : '?${params.join('&')}';

    final res = await _client.get('commitments$query');
    final items = res['data'] as List<dynamic>? ?? const [];
    return items
        .map((e) => Commitment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> close(String id, {String? resolutionNote, bool dismissed = false}) async {
    await _client.patch('commitments/$id/close', body: {
      if (resolutionNote != null && resolutionNote.isNotEmpty) 'resolutionNote': resolutionNote,
      if (dismissed) 'dismissed': true,
    });
  }
}

final commitmentRepositoryProvider = Provider<CommitmentRepository>((ref) {
  return SupabaseCommitmentRepository(ref.read(apiClientProvider));
});
