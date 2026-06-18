import 'package:flutter/material.dart';
import '../theme/app_animations.dart';

class AmStagger extends StatefulWidget {
  const AmStagger({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 30),
    this.staggerDelay = AmAnims.staggerDelay,
    this.duration = AmAnims.staggerDuration,
  });

  final List<Widget> children;
  final Duration delay;
  final Duration staggerDelay;
  final Duration duration;

  @override
  State<AmStagger> createState() => _AmStaggerState();
}

class _AmStaggerState extends State<AmStagger> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fades;
  late final List<Animation<double>> _translates;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
      ),
    );

    _fades = _controllers.map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOut),
    )).toList();

    _translates = _controllers.map((c) => Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOut),
    )).toList();

    _playAnimations();
  }

  Future<void> _playAnimations() async {
    // Await first so context isn't queried synchronously during initState
    await Future.delayed(widget.delay);
    if (!mounted) return;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      for (final controller in _controllers) {
        controller.value = 1.0;
      }
      return;
    }

    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) return;
      _controllers[i].forward();
      await Future.delayed(widget.staggerDelay);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: widget.children,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Opacity(
              opacity: _fades[index].value,
              child: Transform.translate(
                offset: Offset(0, _translates[index].value),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}

class AmAnimateIn extends StatefulWidget {
  const AmAnimateIn({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 30),
    this.staggerDelay = AmAnims.staggerDelay,
    this.duration = AmAnims.staggerDuration,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration staggerDelay;
  final Duration duration;

  @override
  State<AmAnimateIn> createState() => _AmAnimateInState();
}

class _AmAnimateInState extends State<AmAnimateIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _translate = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _play();
  }

  Future<void> _play() async {
    final totalDelay = widget.delay + (widget.staggerDelay * widget.index);
    await Future.delayed(totalDelay);
    if (!mounted) return;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _controller.value = 1.0;
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _translate.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
