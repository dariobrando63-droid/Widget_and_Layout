import 'package:flutter/material.dart';

/// Tombol utama berbentuk pil untuk aksi akun dan onboarding.
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.arrow_forward_rounded,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: Row(
        children: [
          const Spacer(),
          if (busy)
            const SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(label),
          const Spacer(),
          if (!busy)
            CircleAvatar(
              radius: 17,
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(
                alpha: 0.14,
              ),
              child: Icon(icon, size: 19),
            ),
        ],
      ),
    ),
  );
}
