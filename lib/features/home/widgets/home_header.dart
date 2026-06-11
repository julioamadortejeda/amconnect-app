import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/widgets/am_icon_btn.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.agentName,
    required this.urgentCount,
  });
  final String agentName;
  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset('assets/logo/logo_t.png', width: 38, height: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeTitle,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                        color: cs.tertiary, letterSpacing: 0.02)),
                Text(
                  agentName.isNotEmpty
                      ? l10n.homeGreeting(agentName.split(' ').first)
                      : l10n.homeGreetingDefault,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                      color: cs.onSurface, letterSpacing: -0.01),
                ),
              ],
            ),
          ),
          AmIconBtn(
            icon: Icons.notifications_outlined,
            onTap: () => context.push('/agenda'),
            tone: AmIconBtnTone.soft,
            dot: urgentCount > 0,
          ),
        ],
      ),
    );
  }
}
