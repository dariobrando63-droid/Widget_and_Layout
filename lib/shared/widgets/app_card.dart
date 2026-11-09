import 'package:flutter/material.dart';

/// Permukaan kartu dengan garis ringan dan radius sistem desain.
class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.padding = const EdgeInsets.all(20), super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}
