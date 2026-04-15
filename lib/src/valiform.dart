import 'package:flutter/widgets.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

/// A cross-field validator that targets a specific field path.
class VFieldValidator {
  /// The field path this validator targets.
  final String path;

  /// The validation function that receives the full form data.
  final bool Function(Map<String, dynamic> data) check;

  /// Optional custom error message.
  final String? message;

  /// Creates a [VFieldValidator] targeting [path] with a [check] function.
  const VFieldValidator({
    required this.path,
    required this.check,
    this.message,
  });
}

/// Stores cross-field validators associated with a VMap instance.
final formFieldValidators =
    Expando<List<VFieldValidator>>('formFieldValidators');

/// Extension on `VMap` for adding cross-field validation
/// that integrates with `VForm` individual field validators.
extension VMapFormExtension on VMap {
  /// Adds a cross-field validator targeting a specific field path.
  ///
  /// This method calls `refineField()` on the VMap (for `silentValidate`)
  /// and stores the validator for `VForm` to use on individual fields.
  VMap refineFormField(
    bool Function(Map<String, dynamic> data) check, {
    required String path,
    String? message,
  }) {
    refineField(check, path: path, message: message);

    final validators = formFieldValidators[this] ?? [];
    validators.add(VFieldValidator(path: path, check: check, message: message));
    formFieldValidators[this] = validators;

    return this;
  }
}

/// Extension on `VMap` for creating a form directly.
extension VMapExtension on VMap {
  /// Converts a `VMap` into a `VForm<Map<String, dynamic>>`.
  VForm<Map<String, dynamic>> form({
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
    void Function(Map<String, dynamic> value)? onValueChanged,
  }) {
    return VForm<Map<String, dynamic>>.map(
      this,
      formKey: formKey,
      defaultValues: defaultValues,
      onValueChanged: onValueChanged,
    );
  }
}

/// Extension on `VObject<T>` for creating a typed form.
extension VObjectExtension<T> on VObject<T> {
  /// Converts a `VObject<T>` into a `VForm<T>`.
  ///
  /// Requires a [builder] to construct `T` from the collected field values.
  /// Accepts an optional [defaultValue] of type `T` to set initial field values.
  VForm<T> form({
    required T Function(Map<String, dynamic> data) builder,
    GlobalKey<FormState>? formKey,
    T? defaultValue,
    void Function(T value)? onValueChanged,
  }) {
    return VForm<T>.object(
      this,
      builder: builder,
      formKey: formKey,
      defaultValue: defaultValue,
      onValueChanged: onValueChanged,
    );
  }
}
