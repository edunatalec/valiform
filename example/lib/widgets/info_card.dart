import 'package:flutter/material.dart';

/// Rounded container with body text — used in example pages to explain what
/// each page demonstrates. Use [InfoCard.highlight] for callouts that need
/// to stand out (tertiary container color scheme).
class InfoCard extends StatelessWidget {
  final String text;
  final bool _highlight;

  const InfoCard(this.text, {super.key}) : _highlight = false;

  const InfoCard.highlight(this.text, {super.key}) : _highlight = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _highlight
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _highlight
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}
