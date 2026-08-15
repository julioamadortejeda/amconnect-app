import 'package:flutter/material.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

class NotificationsPermissionBanner extends StatelessWidget {
  const NotificationsPermissionBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;

    return AmPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AmDimens.cardPad, vertical: AmDimens.gapS),
        decoration: BoxDecoration(
          color: am.amberWash,
          borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined, size: 20, color: am.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeNotificationsBannerTitle,
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600, color: am.amber),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeNotificationsBannerSubtitle,
                    style: TextStyle(fontSize: 12.5, color: am.amber.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: am.amber),
          ],
        ),
      ),
    );
  }
}
