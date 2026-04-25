import 'package:flutter/widgets.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

/// Extension on `VMap` for creating a form directly.
extension VMapExtension on VMap {
  /// Converts a `VMap` into a `VForm<Map<String, dynamic>>`.
  VForm<Map<String, dynamic>> form({
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? initialValues,
    void Function(Map<String, dynamic> value)? onValueChanged,
  }) {
    return VForm<Map<String, dynamic>>.map(
      this,
      formKey: formKey,
      initialValues: initialValues,
      onValueChanged: onValueChanged,
    );
  }
}

/// Extension on `VObject<T>` for creating a typed form.
extension VObjectExtension<T> on VObject<T> {
  /// Converts a `VObject<T>` into a `VForm<T>`.
  ///
  /// Requires a [builder] to construct `T` from the collected field values.
  /// Accepts an optional [initialValue] of type `T` to set initial field values.
  VForm<T> form({
    required T Function(Map<String, dynamic> data) builder,
    GlobalKey<FormState>? formKey,
    T? initialValue,
    void Function(T value)? onValueChanged,
  }) {
    return VForm<T>.object(
      this,
      builder: builder,
      formKey: formKey,
      initialValue: initialValue,
      onValueChanged: onValueChanged,
    );
  }
}
