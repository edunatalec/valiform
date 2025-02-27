import 'package:flutter/widgets.dart';
import 'package:valiform/valiform.dart';

/// Provides an extension on `Validart` to simplify the creation of `VForm`.
///
/// This extension allows creating a form directly from a `Validart` instance
/// using `v.form(map)`, making form initialization more intuitive.
///
/// ### Example
/// ```dart
/// final form = v.form(
///   v.map({
///     'email': v.string().email(),
///     'password': v.string().password(),
///   }),
/// );
///
/// print(form.validate()); // Returns true if valid
/// ```
extension ValidartExtension on Validart {
  /// Creates a `VForm` from a `VMap` validation schema.
  ///
  /// This method simplifies the process of initializing a form by directly
  /// calling `.form(map)`, instead of manually instantiating `VForm`.
  ///
  /// ### Parameters:
  /// - [map]: The validation schema (`VMap`) defining form fields.
  /// - [formKey]: *(optional)* A custom `GlobalKey<FormState>` to track form state.
  /// - [defaultValues]: *(optional)* A map containing default values for form fields.
  ///
  /// ### Returns:
  /// A new `VForm` instance.
  ///
  /// ### Example
  /// ```dart
  /// final v = Validart();
  ///
  /// final form = v.form(
  ///   v.map({
  ///     'email': v.string().email(),
  ///     'age': v.int().min(18),
  ///   }),
  ///   defaultValues: {'email': 'user@example.com', 'age': 25},
  /// );
  /// ```
  VForm form(
    VMap map, {
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
  }) {
    return VForm(
      map,
      formKey: formKey,
      defaultValues: defaultValues,
    );
  }
}

/// Provides an extension on `VMap` to allow direct form creation.
///
/// Instead of calling `v.form(map)`, this extension enables `map.form()`,
/// making the syntax more natural when working with validation schemas.
///
/// ### Example
/// ```dart
/// final form = v.map({
///   'email': v.string().email(),
///   'password': v.string().password(),
/// }).form();
///
/// print(form.validate()); // Returns true if valid
/// ```
extension VMapExtension on VMap {
  /// Converts a `VMap` into a `VForm`, enabling direct form handling.
  ///
  /// This method allows calling `.form()` directly on a `VMap` validation schema,
  /// simplifying the workflow of form validation.
  ///
  /// ### Parameters:
  /// - [formKey]: *(optional)* A `GlobalKey<FormState>` for managing form state.
  /// - [defaultValues]: *(optional)* A map containing default values for form fields.
  ///
  /// ### Returns:
  /// A new `VForm` instance.
  ///
  /// ### Example
  /// ```dart
  /// final form = v.map({
  ///   'email': v.string().email(),
  ///   'password': v.string().password(),
  /// }).form();
  ///
  /// print(form.validate()); // Returns true if valid
  /// ```
  VForm form({
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
  }) {
    return VForm(
      this,
      formKey: formKey,
      defaultValues: defaultValues,
    );
  }
}
