import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/forgot_password_provider.dart';
import 'auth_error_msg.dart';
import 'auth_field.dart';
import 'auth_submit_btn.dart';
import '../../../l10n/app_localizations.dart';

/// Paso 2 de recuperación de contraseña: código + nueva contraseña.
class ForgotPasswordResetStep extends ConsumerWidget {
  const ForgotPasswordResetStep({
    super.key,
    required this.l10n,
    required this.state,
    required this.codeCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.scale,
    required this.vScale,
    required this.onSubmit,
    required this.onBackToEmail,
  });

  final AppLocalizations l10n;
  final ForgotPasswordState state;
  final TextEditingController codeCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final double scale;
  final double vScale;
  final VoidCallback onSubmit;
  final VoidCallback onBackToEmail;

  String? _errorMsg() => switch (state.error) {
        ForgotPasswordError.emptyFields => l10n.errFillAll,
        ForgotPasswordError.passwordMismatch => l10n.errPasswordMismatch,
        ForgotPasswordError.invalidCode => l10n.errInvalidCode,
        _ => null,
      };

  bool get _canSubmit =>
      codeCtrl.text.trim().isNotEmpty &&
      passCtrl.text.isNotEmpty &&
      confirmCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMsg = _errorMsg();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AuthField(
          controller: codeCtrl,
          hint: l10n.fieldCode,
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 12 * vScale),
        AuthField(
          controller: passCtrl,
          hint: l10n.fieldPassword,
          icon: Icons.lock_outline,
          obscure: obscurePass,
          textInputAction: TextInputAction.next,
          suffixIcon: GestureDetector(
            onTap: onTogglePass,
            child: Icon(
              obscurePass
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AmColors.white,
              size: 20,
            ),
          ),
        ),
        SizedBox(height: 12 * vScale),
        AuthField(
          controller: confirmCtrl,
          hint: l10n.fieldConfirm,
          icon: Icons.lock_outline,
          obscure: obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffixIcon: GestureDetector(
            onTap: onToggleConfirm,
            child: Icon(
              obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AmColors.white,
              size: 20,
            ),
          ),
        ),
        if (errorMsg != null) ...[
          SizedBox(height: 10 * vScale),
          AuthErrorMsg(
            message: errorMsg,
            scale: scale,
            onDismiss: () =>
                ref.read(forgotPasswordProvider.notifier).clearError(),
          ),
        ],
        SizedBox(height: 20 * vScale),
        AuthSubmitBtn(
          label: l10n.forgotPasswordResetBtn,
          enabled: _canSubmit,
          isLoading: state.isLoading,
          onTap: onSubmit,
        ),
        SizedBox(height: 14 * vScale),
        GestureDetector(
          onTap: onBackToEmail,
          child: Text(
            l10n.forgotPasswordBackToEmail,
            style: TextStyle(
              fontSize: 13 * scale,
              color: AmColors.authSubtitle,
              decoration: TextDecoration.underline,
              decorationColor: AmColors.authSubtitle,
            ),
          ),
        ),
      ],
    );
  }
}
