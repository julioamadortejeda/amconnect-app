import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';

class AccountThemeSelector extends ConsumerWidget {
  const AccountThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<ThemeMode>(
        groupValue: currentMode,
        backgroundColor: cs.secondaryContainer,
        thumbColor: cs.surface,
        children: {
          ThemeMode.system: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.brightness_auto_outlined,
                  size: 16,
                  color: currentMode == ThemeMode.system ? cs.primary : cs.tertiary,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.themeModeSystem,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: currentMode == ThemeMode.system ? cs.onSurface : cs.tertiary,
                  ),
                ),
              ],
            ),
          ),
          ThemeMode.light: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.light_mode_outlined,
                  size: 16,
                  color: currentMode == ThemeMode.light ? cs.primary : cs.tertiary,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.themeModeLight,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: currentMode == ThemeMode.light ? cs.onSurface : cs.tertiary,
                  ),
                ),
              ],
            ),
          ),
          ThemeMode.dark: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dark_mode_outlined,
                  size: 16,
                  color: currentMode == ThemeMode.dark ? cs.primary : cs.tertiary,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.themeModeDark,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: currentMode == ThemeMode.dark ? cs.onSurface : cs.tertiary,
                  ),
                ),
              ],
            ),
          ),
        },
        onValueChanged: (mode) {
          if (mode != null) {
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
          }
        },
      ),
    );
  }
}
