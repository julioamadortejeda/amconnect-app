import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../data/feed_item.dart';

enum FeedViewMode { ingest, knowledge }

class FeedViewModeNotifier extends Notifier<FeedViewMode> {
  @override
  FeedViewMode build() => FeedViewMode.knowledge;

  void toggle(FeedViewMode mode) {
    state = mode;
  }
}

final feedViewModeProvider =
    NotifierProvider<FeedViewModeNotifier, FeedViewMode>(FeedViewModeNotifier.new);

final knowledgeStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(noteRepositoryProvider).getNotesSummary();
});

class KnowledgeSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String newQuery) {
    state = newQuery;
  }
}

final knowledgeSearchQueryProvider =
    NotifierProvider<KnowledgeSearchQuery, String>(KnowledgeSearchQuery.new);

final knowledgeListProvider = FutureProvider<List<FeedItem>>((ref) async {
  final query = ref.watch(knowledgeSearchQueryProvider);
  return ref.read(noteRepositoryProvider).searchNotes(query: query);
});
