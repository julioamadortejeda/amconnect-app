import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmPress extends StatefulWidget {
  const AmPress({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.96});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<AmPress> createState() => _AmPressState();
}

class _AmPressState extends State<AmPress> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _anim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Sin acción no hay respuesta táctil.
  ///
  /// El vibrado y el encogido vivían en `onTapDown`, que corre siempre — así
  /// que una fila sin `onTap` (un compromiso sin cliente al que ir, por
  /// ejemplo) vibraba y se encogía para luego no hacer nada. El mismo principio
  /// que ya aplica `AmIconBtn` con su estado deshabilitado: lo que no responde
  /// no debe sentirse igual que lo que sí.
  bool get _hasAction => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (!_hasAction) return;
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPressStart: widget.onLongPress != null
          ? (_) {
              HapticFeedback.mediumImpact();
              _ctrl.forward();
            }
          : null,
      onLongPress: widget.onLongPress != null
          ? () {
              _ctrl.reverse();
              widget.onLongPress!();
            }
          : null,
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}
