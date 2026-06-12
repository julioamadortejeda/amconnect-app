import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/am_press.dart';

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: AmPress(
        onTap: () => context.pop(),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
