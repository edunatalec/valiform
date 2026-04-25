import 'package:flutter/material.dart';

/// Translucent red banner used by example pages to render
/// `form.rootErrors` (schema-level errors with no field path — e.g. emitted
/// by `refine(..., dependsOn:)` or `equalFields`). Renders nothing when
/// [messages] is empty, so it is safe to drop into a `ListenableBuilder`
/// that watches `form.listenable`.
class RootErrorBanner extends StatelessWidget {
  final List<String> messages;

  const RootErrorBanner({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in messages)
            Text(
              '• $m',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
        ],
      ),
    );
  }
}
