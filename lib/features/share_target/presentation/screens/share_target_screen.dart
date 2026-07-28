import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/widgets/am_press.dart';
import '../../../../core/widgets/am_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/share_target_provider.dart';
import '../../widgets/share_destination_notice.dart';
import '../../widgets/share_destination_selector.dart';
import '../../widgets/share_preview_card.dart';

class ShareTargetScreen extends ConsumerWidget {
  const ShareTargetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(shareTargetProvider);

    void close() {
      final notifier = ref.read(shareTargetProvider.notifier);
      notifier.clearSelection();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    Future<void> submit() async {
      final notifier = ref.read(shareTargetProvider.notifier);
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      if (!await notifier.validate()) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.translateError(ref.read(shareTargetProvider).error)),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Cerrar primero: los sheets del overlay de ingesta usan el mismo
      // navigator que GoRouter, así que despachar antes haría que este pop
      // cerrara el sheet en vez de la pantalla.
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/home');
      }
      notifier.dispatch();
      notifier.clearSelection();
    }

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.shareTargetTitle,
        showBack: true,
        onBack: close,
      ),
      body: SafeArea(
        top: false,
        child: !state.hasContent
            ? Center(
                child: Text(
                  l10n.shareTargetEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.tertiary),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, 40),
                children: [
                  SharePreviewCard(
                    files: state.sharedFiles,
                    text: state.sharedText,
                  ),
                  const SizedBox(height: AmDimens.gapL),
                  const ShareDestinationSelector(),
                  const SizedBox(height: AmDimens.gapM),
                  ShareDestinationNotice(state: state),
                  const SizedBox(height: AmDimens.gapL),
                  AmPress(
                    onTap: state.canSubmit ? submit : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: state.canSubmit ? cs.primary : cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        state.destinationType == ShareDestinationType.policyIngest
                            ? l10n.shareTargetActionPolicyIngest
                            : l10n.shareTargetActionIngest,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: state.canSubmit ? cs.onPrimary : cs.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AmDimens.gapM),
                  TextButton(
                    onPressed: close,
                    child: Text(l10n.shareTargetCancel),
                  ),
                ],
              ),
      ),
    );
  }
}
