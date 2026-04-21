import 'package:flutter/material.dart';

import '../utils.dart';

/// Translucent coloured box that shows either the parsed form value
/// (green, on success) or the validation errors (red, on failure). Used
/// across the example pages to visualise submit outcomes consistently.
class ResultBox extends StatelessWidget {
  final String title;
  final String body;
  final MaterialColor color;

  const ResultBox._({
    required this.title,
    required this.body,
    required this.color,
  });

  factory ResultBox.success({required Map<String, dynamic> data}) {
    return ResultBox._(
      title: 'Form is valid',
      body: prettyJson(data),
      color: Colors.green,
    );
  }

  factory ResultBox.failure({required Map<String, String> errors}) {
    return ResultBox._(
      title: 'Form has errors',
      body: prettyJson(errors),
      color: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Null-aware wrapper around [ResultBox] that also owns the top spacing.
/// Drop-in replacement for the recurring
/// `if (result != null) ...[SizedBox, ResultBox.success] else if (errors
/// != null) ...[SizedBox, ResultBox.failure]` pattern across the example
/// pages. Renders nothing until either [data] or [errors] is non-null.
class ResultFeedback extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Map<String, String>? errors;
  final double spacing;

  const ResultFeedback({
    super.key,
    this.data,
    this.errors,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? box;
    if (data != null) {
      box = ResultBox.success(data: data!);
    } else if (errors != null) {
      box = ResultBox.failure(errors: errors!);
    } else {
      box = null;
    }

    if (box == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: spacing),
      child: box,
    );
  }
}
