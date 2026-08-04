import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/forgot_password_provider.dart';
import 'auth_error_msg.dart';
import 'auth_field.dart';
import 'auth_submit_btn.dart';
import '../../../l10n/app_localizations.dart';

/// Paso 1 de recuperación de contraseña: captura de email y envío de código.
class ForgotPasswordEmailStep extends ConsumerWidget {
  const ForgotPasswordEmailStep({
    super.key,
    required this.l10n,
    required this.state,
    required this.emailCtrl,
    required this.scale,
    required this.vScale,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final ForgotPasswordState state;
  final TextEditingController emailCtrl;
  final double scale;
  final double vScale;
  final VoidCallback onSubmit;

  String? _errorMsg() => switch (state.error) {
        ForgotPasswordError.emptyEmail => l10n.errEmptyCredentials,
        ForgotPasswordError.invalidEmail => l10n.errInvalidEmail,
        ForgotPasswordError.requestFailed => l10n.errRequestCodeFailed,
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMsg = _errorMsg();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AuthField(
          controller: emailCtrl,
          hint: l10n.fieldEmail,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
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
          label: l10n.forgotPasswordSendCodeBtn,
          enabled: emailCtrl.text.trim().isNotEmpty,
          isLoading: state.isLoading,
          onTap: onSubmit,
        ),
      ],
    );
  }
}
