import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'auth_submit_btn.dart';
import '../../../l10n/app_localizations.dart';

/// Vista de éxito tras completar el restablecimiento de contraseña.
class ForgotPasswordSuccessView extends StatelessWidget {
  const ForgotPasswordSuccessView({
    super.key,
    required this.l10n,
    required this.scale,
    required this.vScale,
  });

  final AppLocalizations l10n;
  final double scale;
  final double vScale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72 * scale,
            height: 72 * scale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                size: 38 * scale, color: Colors.white),
          ),
          SizedBox(height: 20 * vScale),
          Text(
            l10n.forgotPasswordSuccessTitle,
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8 * vScale),
          Text(
            l10n.forgotPasswordSuccessMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * scale,
              color: AmColors.authSubtitle,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28 * vScale),
          AuthSubmitBtn(
            label: l10n.forgotPasswordSuccessBtn,
            enabled: true,
            isLoading: false,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
