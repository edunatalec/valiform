import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';

/// Example wrapper that wires a [VField<String>] to a [TextFormField].
///
/// Forwards [VField.key], [VField.textController] (if a controller was
/// attached via `attachTextController`), [VField.validator], and
/// [VField.onChanged] — skipping `onChanged` when a controller is present
/// (the controller listener already pushes updates into the field).
///
/// For the common case, pass [label] and [hint] directly. For full
/// customization (prefix/suffix icons, fill color, etc.), pass a
/// [decoration] — it wins over [label]/[hint].
///
/// This widget is **not** part of the valiform package. It lives in the
/// example so readers can copy/paste or adapt it. The library intentionally
/// avoids shipping widgets to stay uncoupled from any design system — build
/// your own wrapper around your preferred input widget.
class VTextField extends StatelessWidget {
  final VField<String> field;
  final String? label;
  final String? hint;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final bool enabled;

  const VTextField({
    super.key,
    required this.field,
    this.label,
    this.hint,
    this.decoration,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = field.textController;
    return TextFormField(
      key: field.key,
      controller: controller,
      initialValue: controller == null ? field.value : null,
      decoration:
          decoration ?? InputDecoration(labelText: label, hintText: hint),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      enabled: enabled,
      validator: field.validator,
      onChanged: controller == null ? field.onChanged : null,
    );
  }
}
