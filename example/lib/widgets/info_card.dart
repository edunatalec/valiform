import 'package:flutter/material.dart';

/// Rounded container with body text — used in example pages to explain what
/// each page demonstrates.
class InfoCard extends StatelessWidget {
  final String text;

  const InfoCard(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}
