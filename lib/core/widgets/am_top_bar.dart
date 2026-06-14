import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_dimensions.dart';

/// AppBar reutilizable con estilo transparente y sin sombra.
///
/// Soporta título de una o dos líneas (subtitle encima del title),
/// acciones arbitrarias y back button opcional.
class AmTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AmTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
    this.onBack,
  });

  final String title;

  /// Texto pequeño encima del título (ej. "7 pendientes").
  /// Cuando se provee, la altura del AppBar aumenta a 64.
  final String? subtitle;

  final List<Widget> actions;

  /// Muestra el botón de regreso (chevron_left). Llama a [onBack] si se
  /// provee, o a context.pop() por defecto.
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 64.0 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titleWidget = subtitle != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: cs.tertiary,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  letterSpacing: -0.01,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        : Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              letterSpacing: -0.01,
            ),
            overflow: TextOverflow.ellipsis,
          );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: subtitle != null ? 64.0 : kToolbarHeight,
      titleSpacing: AmDimens.screenH,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.chevron_left, size: 26),
              color: cs.onSurface,
              onPressed: onBack ?? () => context.pop(),
              padding: EdgeInsets.zero,
            )
          : null,
      title: titleWidget,
      actions: actions,
    );
  }
}
