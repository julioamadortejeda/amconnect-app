import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/knowledge_dashboard_provider.dart';
import 'feed_row.dart';
import 'knowledge_search_bar.dart';
import 'knowledge_stat_card.dart';

/// Vista "Base de conocimiento" del Feed: stats, búsqueda y lista paginada
/// de notas con scroll infinito.
class KnowledgeDashboardView extends ConsumerStatefulWidget {
  const KnowledgeDashboardView({super.key});

  @override
  ConsumerState<KnowledgeDashboardView> createState() =>
      _KnowledgeDashboardViewState();
}

class _KnowledgeDashboardViewState
    extends ConsumerState<KnowledgeDashboardView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(knowledgeListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(knowledgeStatsProvider);
    final searchListAsync = ref.watch(knowledgeListProvider);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
          AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
      children: [
        const SizedBox(height: AmDimens.gapS),

        // ── Stats Section ────────────────────────────────────────
        AmAnimateIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmSectionLabel(label: l10n.feedStatsTitle),
              const SizedBox(height: AmDimens.gapXS),
              statsAsync.when(
                loading: () => const AmLoader(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  children: [
                    KnowledgeStatCard(
                      label: l10n.feedStatsPDFs,
                      count: stats['pdf'] ?? 0,
                      icon: AmIcons.pdf,
                      color: AmColors.srcDoc,
                    ),
                    KnowledgeStatCard(
                      label: l10n.feedStatsImages,
                      count: stats['image'] ?? 0,
                      icon: AmIcons.image,
                      color: AmColors.srcImage,
                    ),
                    KnowledgeStatCard(
                      label: l10n.feedStatsAudios,
                      count: stats['audio'] ?? 0,
                      icon: AmIcons.audio,
                      color: AmColors.srcWave,
                    ),
                    KnowledgeStatCard(
                      label: l10n.feedStatsNotes,
                      count: stats['text'] ?? 0,
                      icon: AmIcons.text,
                      color: AmColors.srcNote,
                    ),
                    KnowledgeStatCard(
                      label: l10n.feedStatsChats,
                      count: stats['chat'] ?? 0,
                      icon: AmIcons.whatsapp,
                      color: AmColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Search Section ────────────────────────────────────────
        const AmAnimateIn(
          index: 1,
          child: KnowledgeSearchBar(),
        ),

        const SizedBox(height: 20),

        // ── Notes List Section ────────────────────────────────────
        AmAnimateIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmSectionLabel(label: l10n.feedAllNotesTitle),
              const SizedBox(height: 10),
              searchListAsync.when(
                loading: () => const AmLoader(),
                error: (_, __) => Text(
                  l10n.errUnknown,
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
                data: (listState) {
                  if (listState.items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          l10n.feedSearchNoResults,
                          style: TextStyle(color: cs.tertiary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      ...listState.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: AmDimens.gapS),
                        child: FeedRow(item: item),
                      )),
                      if (listState.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: AmLoader(),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
