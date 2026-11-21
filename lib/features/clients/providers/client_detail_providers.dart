import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/models/reminder.dart';
import '../../../core/repositories/supabase_contact_repository.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../../../core/repositories/supabase_reminder_repository.dart';
import '../../../core/repositories/supabase_policy_repository.dart';
import '../../../core/models/ai_chat_context.dart';
import '../../home/providers/home_provider.dart';
import 'clients_list_provider.dart';
import 'policies_provider.dart';

/// Fuerza la carga de todas las páginas de clientes y pólizas — para
/// pantallas que necesitan la cartera completa (selectores, analytics),
/// no solo lo que ya esté cargado por scroll. `autoDispose` para que se
/// vuelva a evaluar cada vez que la pantalla que lo usa se vuelve a montar.
final ensureFullPortfolioDataProvider = FutureProvider.autoDispose<void>((ref) async {
  await Future.wait([
    ref.read(clientsProvider.notifier).loadAll(),
    ref.read(policiesProvider.notifier).loadAll(),
  ]);
});

/// Agrupa recordatorios activos por contactId — sin red, derivado de remindersProvider.
final contactRemindersMapProvider = Provider<Map<String, List<Reminder>>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final map = <String, List<Reminder>>{};
  for (final r in reminders) {
    if (!r.isActive) continue;
    final cid = r.contactId;
    if (cid == null) continue;
    (map[cid] ??= []).add(r);
  }
  return map;
});

final contactDetailProvider =
    FutureProvider.family<Contact, String>((ref, id) async {
  return ref.read(contactRepositoryProvider).getById(id);
});

final contactPoliciesProvider =
    FutureProvider.family<List<Policy>, String>((ref, contactId) async {
  return ref.read(policyRepositoryProvider).getByContactId(contactId);
});

// Watching this provider activates Realtime for policies of a contact.
// autoDispose ensures the channel closes when the screen is popped.
final contactPoliciesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, contactId) {
  final channel = Supabase.instance.client
      .channel('policies:contact:$contactId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'policies',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'contact_id',
          value: contactId,
        ),
        callback: (_) => ref.invalidate(contactPoliciesProvider(contactId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

final contactNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, contactId) async {
  return ref.read(noteRepositoryProvider).getByContactId(contactId);
});

final policyNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, policyId) async {
  return ref.read(noteRepositoryProvider).getByPolicyId(policyId);
});

/// Recordatorios de una póliza — incluye los cerrados, porque es el historial
/// de pagos y renovaciones que se muestra en su detalle.
final policyRemindersProvider =
    FutureProvider.family<List<Reminder>, String>((ref, policyId) async {
  return ref.read(reminderRepositoryProvider).getByPolicy(policyId);
});

/// Observar este provider mantiene al día la actividad de una póliza.
final policyRemindersRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, policyId) {
  final channel = Supabase.instance.client
      .channel('reminders:policy:$policyId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reminders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'policy_id',
          value: policyId,
        ),
        callback: (_) => ref.invalidate(policyRemindersProvider(policyId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

// Watching this provider activates Realtime for notes of a contact.
final contactNotesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, contactId) {
  final channel = Supabase.instance.client
      .channel('notes:contact:$contactId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'agent_notes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'contact_id',
          value: contactId,
        ),
        callback: (_) => ref.invalidate(contactNotesProvider(contactId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

// Watching this provider activates Realtime for notes of a policy — necesario
// porque la ingesta de archivo/texto con IA es asíncrona (tarda segundos) y
// nada más refresca policyNotesProvider cuando termina.
final policyNotesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, policyId) {
  final channel = Supabase.instance.client
      .channel('notes:policy:$policyId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'agent_notes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'policy_id',
          value: policyId,
        ),
        callback: (_) => ref.invalidate(policyNotesProvider(policyId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

/// Contexto de IA listo para enviar al chat, construido con los datos
/// ya cargados en pantalla (contacto + pólizas + notas).
final contactAiContextProvider =
    Provider.family<AiChatContext, String>((ref, contactId) {
  final contact = ref.watch(clientsProvider).asData?.value
          .where((c) => c.id == contactId)
          .firstOrNull ??
      ref.watch(contactDetailProvider(contactId)).asData?.value;

  if (contact == null) {
    return AiChatContext(type: 'contact', id: contactId, data: {});
  }

  final policies = ref.watch(contactPoliciesProvider(contactId)).asData?.value;
  final contactNotes = ref.watch(contactNotesProvider(contactId)).asData?.value ?? [];

  // El asesor espera que el chat "sepa" todo sobre el cliente, incluidas las
  // notas que se agregaron desde el detalle de una póliza suya (note_origin
  // 'policy') — no solo las de conocimiento general (note_origin 'knowledge').
  final policyNotes = <AgentNote>[
    for (final p in policies ?? <Policy>[])
      ...(ref.watch(policyNotesProvider(p.id)).asData?.value ?? <AgentNote>[]),
  ];

  return AiChatContext.fromContact(
    contact,
    policies: policies,
    notes: [...contactNotes, ...policyNotes],
  );
});
