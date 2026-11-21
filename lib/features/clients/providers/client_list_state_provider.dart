import 'package:flutter_riverpod/flutter_riverpod.dart';

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final clientSearchProvider =
    NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);

class _PolicySearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final policySearchProvider =
    NotifierProvider<_PolicySearchNotifier, String>(_PolicySearchNotifier.new);

/// Estado de paginación de una lista con scroll infinito — separado del
/// `state` del AsyncNotifier (que sigue siendo `List<T>` puro, sin romper
/// a los ~10 lugares que ya consumen `clientsProvider`/`policiesProvider`).
class ListPageInfo {
  const ListPageInfo({
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  ListPageInfo copyWith({int? page, bool? hasMore, bool? isLoadingMore}) =>
      ListPageInfo(
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _ClientsPageNotifier extends Notifier<ListPageInfo> {
  @override
  ListPageInfo build() => const ListPageInfo();
  void set(ListPageInfo v) => state = v;
}

final clientsPageInfoProvider =
    NotifierProvider<_ClientsPageNotifier, ListPageInfo>(_ClientsPageNotifier.new);

class _PoliciesPageNotifier extends Notifier<ListPageInfo> {
  @override
  ListPageInfo build() => const ListPageInfo();
  void set(ListPageInfo v) => state = v;
}

final policiesPageInfoProvider =
    NotifierProvider<_PoliciesPageNotifier, ListPageInfo>(_PoliciesPageNotifier.new);
