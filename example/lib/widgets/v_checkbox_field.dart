import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';

/// Example custom `FormField<bool>` that binds a [VField<bool>] to a
/// [CheckboxListTile] and surfaces validation errors below the tile.
///
/// Parallels `VTextField`, but instead of wrapping a `TextFormField` in a
/// `StatelessWidget` it *extends* `FormField<bool>` directly — mirroring
/// how Flutter ships `TextFormField extends FormField<String>`. This is
/// the shape you'd use for any custom, validated input where the value
/// space isn't text.
///
/// Wires three things to the [VField]:
/// - `key: field.key` — lets `field.setError(...)` revalidate just this
///   single field via `key.currentState?.validate()`.
/// - `validator: (_) => field.validator(field.value)` — the schema/manual
///   error pipeline drives the `FormField` error.
/// - `ListenableBuilder(listenable: field.listenable, ...)` — programmatic
///   `field.set(...)` refreshes the checkbox UI, not just the explicit
///   `onChanged` path.
///
/// This widget is **not** part of the valiform package. It lives in the
/// example so readers can copy/paste or adapt it. The library intentionally
/// avoids shipping widgets to stay uncoupled from any design system — build
/// your own wrapper around your preferred input widget.
class VCheckboxField extends FormField<bool> {
  VCheckboxField({
    required VField<bool> field,
    required String title,
    Widget? subtitle,
    bool enabled = true,
  }) : super(
          // Always use field.key — no external key: setError(...) relies on
          // this GlobalKey to revalidate just this field.
          key: field.key,
          initialValue: field.value ?? false,
          validator: (_) => field.validator(field.value),
          builder: (state) {
            return ListenableBuilder(
              listenable: field.listenable,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Text(title),
                      subtitle: subtitle,
                      value: field.value ?? false,
                      onChanged: enabled
                          ? (val) {
                              field.set(val);
                              state.didChange(val);
                            }
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(state.context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
}
