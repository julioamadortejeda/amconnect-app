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

// ── Pagination state ────────────────────────────────────────────────────────

class KnowledgeListState {
  const KnowledgeListState({
    required this.items,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<FeedItem> items;
  final bool hasMore;
  final bool isLoadingMore;

  KnowledgeListState copyWith({
    List<FeedItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      KnowledgeListState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class KnowledgeListNotifier extends AsyncNotifier<KnowledgeListState> {
  static const _pageSize = 20;

  @override
  Future<KnowledgeListState> build() async {
    final query = ref.watch(knowledgeSearchQueryProvider);
    final repo = ref.read(noteRepositoryProvider);
    final items = await repo.searchNotes(
      limit: _pageSize,
      offset: 0,
      query: query.trim().isEmpty ? null : query,
    );
    return KnowledgeListState(
      items: items,
      hasMore: items.length == _pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final query = ref.read(knowledgeSearchQueryProvider);
    final repo = ref.read(noteRepositoryProvider);

    try {
      final newItems = await repo.searchNotes(
        limit: _pageSize,
        offset: current.items.length,
        query: query.trim().isEmpty ? null : query,
      );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newItems],
        hasMore: newItems.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final knowledgeListProvider =
    AsyncNotifierProvider<KnowledgeListNotifier, KnowledgeListState>(
  KnowledgeListNotifier.new,
);
