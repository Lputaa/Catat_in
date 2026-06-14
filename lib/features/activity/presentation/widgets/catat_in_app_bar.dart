import 'package:flutter/material.dart';

class CatatInAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? action;

  const CatatInAppBar({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 3,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      centerTitle: false,
      title: Row(
        children: [
          // Interactive animated logo
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Tetap produktif bersama Catat-In! 🔥'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                    ),
                  );
                },
                child: Image.asset(
                  'lib/core/theme/icon.png',
                  width: 34,
                  height: 34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Double stacked title for dynamic feel
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Catat-In',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        action ?? const SizedBox.shrink(),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}
