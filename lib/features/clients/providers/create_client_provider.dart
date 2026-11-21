import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error_mapper.dart';
import 'clients_list_provider.dart';

/// Estado del formulario de creación manual de clientes.
class CreateClientState {
  const CreateClientState({this.loading = false, this.error});

  final bool loading;

  /// errorCode o mensaje crudo del backend — se traduce con
  /// `context.translateError` en la pantalla.
  final String? error;

  CreateClientState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
  }) => CreateClientState(
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

class CreateClientNotifier extends Notifier<CreateClientState> {
  @override
  CreateClientState build() => const CreateClientState();

  Future<Contact?> submit({
    required String fullName,
    String? phone,
    String? email,
    String? birthdate,
    String? occupation,
    String? address,
    String? rfc,
    String? curp,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final created = await ref.read(clientsProvider.notifier).create(
        fullName: fullName,
        phone: phone,
        email: email,
        birthdate: birthdate,
        occupation: occupation,
        address: address,
        rfc: rfc,
        curp: curp,
      );
      state = state.copyWith(loading: false);
      return created;
    } on ApiException catch (e) {
      state = CreateClientState(error: mapApiError(e));
      return null;
    }
  }

  Future<Contact?> updateContact(
    String id, {
    required String fullName,
    String? phone,
    String? email,
    String? birthdate,
    String? occupation,
    String? address,
    String? rfc,
    String? curp,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final updated = await ref.read(clientsProvider.notifier).updateContact(
        id,
        fullName: fullName,
        phone: phone,
        email: email,
        birthdate: birthdate,
        occupation: occupation,
        address: address,
        rfc: rfc,
        curp: curp,
      );
      state = state.copyWith(loading: false);
      return updated;
    } on ApiException catch (e) {
      state = CreateClientState(error: mapApiError(e));
      return null;
    }
  }

  void reset() => state = const CreateClientState();
}

final createClientProvider =
    NotifierProvider<CreateClientNotifier, CreateClientState>(
        CreateClientNotifier.new);
