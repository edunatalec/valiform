/// @docImport 'package:valiform/valiform.dart';
library;

import 'package:flutter/widgets.dart';
import 'package:validart/validart.dart';

import '../valiform.dart';

/// Turns a `VMap` schema into a form.
///
/// See also:
///
///  * [VObjectExtension], the same door for a `VObject<T>` schema.
///  * [VForm], what `form()` returns.
extension VMapExtension on VMap {
  /// Converts a `VMap` into a [VForm] whose value type is
  /// `Map<String, dynamic>`.
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

/// Turns a `VObject<T>` schema into a typed form.
///
/// See also:
///
///  * [VMapExtension], the same door for an untyped `VMap` schema.
///  * [VForm], what `form()` returns.
extension VObjectExtension<T> on VObject<T> {
  /// Converts a `VObject<T>` into a [VForm] whose value type is `T`.
  ///
  /// Requires a [builder] to construct `T` from the collected field values.
  ///
  /// Pre-fill the form via either [initialValue] (a complete `T` instance,
  /// decomposed via `VObject.extract`) or [initialValues] (a partial
  /// `Map<String, dynamic>` keyed by field name; absent fields stay `null`,
  /// unknown keys are ignored). Pass at most one — both is an assertion
  /// error.
  ///
  /// [onValueChanged] receives the current [VForm.rawValue]
  /// (`Map<String, dynamic>`), not the typed `T`. A field change does not
  /// imply the form is valid enough to construct `T`; consumers needing the
  /// typed value should validate first and read [VForm.value] (or
  /// [VForm.valueAsync]).
  VForm<T> form({
    required T Function(Map<String, dynamic> data) builder,
    GlobalKey<FormState>? formKey,
    T? initialValue,
    Map<String, dynamic>? initialValues,
    void Function(Map<String, dynamic> rawValue)? onValueChanged,
  }) {
    return VForm<T>.object(
      this,
      builder: builder,
      formKey: formKey,
      initialValue: initialValue,
      initialValues: initialValues,
      onValueChanged: onValueChanged,
    );
  }
}
