import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';

class AmBackBar extends StatelessWidget {
  const AmBackBar({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 12,
            left: 4,
            right: 8,
          ),
          color: const Color(0xCCF5F6F7),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 26),
                color: AmColors.inkLight,
                onPressed: onBack ?? () => context.pop(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AmColors.mutedLight,
                            letterSpacing: 0.02,
                          )),
                    if (title != null)
                      Text(title!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AmColors.inkLight,
                            letterSpacing: -0.01,
                          ),
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
