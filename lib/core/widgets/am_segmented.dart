import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class AmSegmented extends StatefulWidget {
  const AmSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  State<AmSegmented> createState() => _AmSegmentedState();
}

class _AmSegmentedState extends State<AmSegmented>
    with TickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: widget.options.length,
      initialIndex: _indexOf(widget.selected),
      vsync: this,
    );
    _tabs.addListener(_onTabChange);
  }

  @override
  void didUpdateWidget(AmSegmented old) {
    super.didUpdateWidget(old);
    final newIndex = _indexOf(widget.selected);
    if (newIndex != _tabs.index) _tabs.animateTo(newIndex);
  }

  void _onTabChange() {
    if (!_tabs.indexIsChanging) {
      widget.onSelect(widget.options[_tabs.index]);
    }
  }

  int _indexOf(String option) =>
      widget.options.indexOf(option).clamp(0, widget.options.length - 1);

  @override
  void dispose() {
    _tabs.removeListener(_onTabChange);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
      ),
      child: TabBar(
        controller: _tabs,
        labelColor: cs.onPrimaryContainer,
        unselectedLabelColor: cs.tertiary,
        indicator: BoxDecoration(
          color: AmColors.cardLight,
          borderRadius: BorderRadius.circular(AmDimens.cardRadius - 4),
          boxShadow: [
            BoxShadow(
              color: AmColors.inkLight.withValues(alpha: 0.055),
              blurRadius: 22,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: widget.options.map((o) => Tab(text: o)).toList(),
      ),
    );
  }
}
