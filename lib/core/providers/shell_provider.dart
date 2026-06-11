import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void hide() => state = false;
  void show() => state = true;
}

final shellBarVisibleProvider =
    NotifierProvider<ShellNotifier, bool>(ShellNotifier.new);
